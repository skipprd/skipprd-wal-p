// Live accumulator + Closed offsets for disk WAL. Same take-all flush
// and no restore as S3 IngestCore. Persist goes through DiskWriter.

machine DiskIngestCore {
    var parent: machine;
    var store: DiskStore;
    var log: MutationLog;
    var closed: map[int, bool];
    var live: seq[int];
    var nextId: int;
    var offs: seq[int];
    var hash: int;
    var crashMode: int;
    var restoreBad: bool;
    var wr: (acked: bool, id: int, hash: int);
    var recoverDone: bool;
    var i: int;
    var k: int;

    start state Init {
        entry (input: (parent: machine, store: DiskStore, log: MutationLog)) {
            parent = input.parent;
            store = input.store;
            log = input.log;
            closed = default(map[int, bool]);
            live = emptyKeys();
            nextId = 0;
            goto Serving;
        }
    }

    state Serving {
        on eIngestSubmit do (payload: (key: int)) {
            announce eSubmit, (key=payload.key,);
            if (payload.key in closed) {
                announce eIngestSkip, (key=payload.key,);
            } else {
                live += (sizeof(live), payload.key);
            }
        }

        on eIngestFlush do (payload: (crashMode: int, hash: int, restoreBad: bool)) {
            crashMode = payload.crashMode;
            hash = payload.hash;
            restoreBad = payload.restoreBad;
            offs = live;
            live = emptyKeys();
            if (sizeof(offs) == 0) {
                send parent, eIngestCoreDone, (acked=true, id=-1, hash=hash);
            } else {
                announce eFlushTaken, (id=nextId, hash=hash, offs=offs);
                new DiskWriter((parent=this, store=store, log=log, id=nextId, hash=hash, crashMode=crashMode, offs=offs));
                receive {
                    case eWriterDone: (d: (acked: bool, id: int, hash: int)) {
                        wr = d;
                    }
                }
                if (wr.acked) {
                    i = 0;
                    while (i < sizeof(offs)) {
                        k = offs[i];
                        closed[k] = true;
                        announce eOffsetsClosed, (key=k,);
                        i = i + 1;
                    }
                    nextId = nextId + 1;
                } else {
                    if (restoreBad) {
                        live = offs;
                        nextId = nextId + 1;
                        announce eFlushTaken, (id=nextId, hash=hash, offs=offs);
                        new DiskWriter((parent=this, store=store, log=log, id=nextId, hash=hash, crashMode=0, offs=offs));
                        receive {
                            case eWriterDone: (d2: (acked: bool, id: int, hash: int)) {
                                wr = d2;
                            }
                        }
                        if (wr.acked) {
                            i = 0;
                            while (i < sizeof(offs)) {
                                k = offs[i];
                                closed[k] = true;
                                announce eOffsetsClosed, (key=k,);
                                i = i + 1;
                            }
                        }
                        live = emptyKeys();
                        nextId = nextId + 1;
                    } else {
                        nextId = nextId + 1;
                    }
                }
                new DiskRecover((parent=this, store=store, log=log, maxId=nextId));
                recoverDone = false;
                while (!recoverDone) {
                    receive {
                        case eOffsetsClosed: (p: (key: int)) {
                            closed[p.key] = true;
                        }
                        case eRecoverDone: {
                            recoverDone = true;
                        }
                    }
                }
                send parent, eIngestCoreDone, (acked=wr.acked, id=wr.id, hash=wr.hash);
            }
        }
    }
}
