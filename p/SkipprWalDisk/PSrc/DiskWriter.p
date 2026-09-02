// Disk ingest writer: sync body, log Prepared → Committed, Apply writes
// the commit marker, then ACK. crashMode: 0 none, 1 after body sync,
// 2 after prepared, 3 after committed before apply, 4 after commit before ACK.

machine DiskWriter {
    var parent: machine;
    var store: DiskStore;
    var log: MutationLog;
    var id: int;
    var hash: int;
    var crashMode: int;
    var offs: seq[int];
    var blob: tBlob;
    var ok: bool;

    start state Init {
        entry (input: (parent: machine, store: DiskStore, log: MutationLog, id: int, hash: int, crashMode: int, offs: seq[int])) {
            parent = input.parent;
            store = input.store;
            log = input.log;
            id = input.id;
            hash = input.hash;
            crashMode = input.crashMode;
            offs = input.offs;
            blob = (id=id, hash=hash, offs=offs);
            announce eAppendStart, (id=id, hash=hash);
            goto PutBody;
        }
    }

    state PutBody {
        entry {
            diskPutSynced(this, store, bodyKey(id), blob);
            announce eBodyPut, (id=id, hash=hash);
            if (crashMode == 1) {
                announce eWriterCrash, (id=id, phase=1);
                send parent, eWriterDone, (acked=false, id=id, hash=hash);
                raise halt;
            }
            goto Prepare;
        }
    }

    state Prepare {
        entry {
            logPrepare(this, log, id, hash);
            if (crashMode == 2) {
                announce eWriterCrash, (id=id, phase=2);
                send parent, eWriterDone, (acked=false, id=id, hash=hash);
                raise halt;
            }
            goto Commit;
        }
    }

    state Commit {
        entry {
            logCommit(this, log, id, hash);
            if (crashMode == 3) {
                announce eWriterCrash, (id=id, phase=3);
                send parent, eWriterDone, (acked=false, id=id, hash=hash);
                raise halt;
            }
            goto ApplyCommit;
        }
    }

    state ApplyCommit {
        entry {
            diskPutSynced(this, store, commitKey(id), blob);
            logApply(this, log, id, hash);
            announce eCommitPut, (id=id, hash=hash);
            if (crashMode == 4) {
                announce eWriterCrash, (id=id, phase=4);
                send parent, eWriterDone, (acked=false, id=id, hash=hash);
                raise halt;
            }
            goto Ack;
        }
    }

    state Ack {
        entry {
            announce eIngestAck, (id=id, hash=hash);
            send parent, eWriterDone, (acked=true, id=id, hash=hash);
        }
    }
}
