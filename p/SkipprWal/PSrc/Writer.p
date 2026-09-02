// One ingest writer: PUT body, then PUT commit, then ACK.
// Unconditional PUTs (expected_version = -1). Unique ids are the caller's job.
//
// Unknown persist (timeout): GET-admit this snapshot id, same bind as
// recovery. Bound pair → ACK this id (no new snapshot). GET miss or still
// unknown after retries → panic. Next process Recover owns the pair if it
// exists. Never mint a second id for the same payload.
//
// crashMode: 0 none, 1 halt after body, 2 halt after commit (before ACK),
//   3 after commit, reconcile GET then ACK, 4 skip commit PUT, GET miss, panic,
//   5 after commit, skip GET, panic (GET unknown).

machine Writer {
    var parent: machine;
    var store: ObjectStore;
    var id: int;
    var hash: int;
    var crashMode: int;
    var offs: seq[int];
    var blob: tBlob;
    var res: tPutResult;
    var tries: int;
    var admitted: bool;

    start state Init {
        entry (input: (parent: machine, store: ObjectStore, id: int, hash: int, crashMode: int, offs: seq[int])) {
            parent = input.parent;
            store = input.store;
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
            res = uploadBlob(this, store, bodyKey(id), blob);
            if (res.applied) {
                announce eBodyPut, (id=id, hash=hash);
            }
            if (res.ok) {
                if (crashMode == 1) {
                    announce eWriterCrash, (id=id, phase=1);
                    send parent, eWriterDone, (acked=false, id=id, hash=hash);
                    raise halt;
                }
                goto PutCommit;
            }
            if (res.unknown) {
                goto ReconcileBody;
            }
            assert false, format("body PUT failed for {0}", id);
        }
    }

    state ReconcileBody {
        entry {
            tries = 0;
            admitted = false;
            while (tries < 2 && !admitted) {
                admitted = bodyPresent(this, store, id, hash);
                tries = tries + 1;
            }
            if (admitted) {
                if (!res.applied) {
                    announce eBodyPut, (id=id, hash=hash);
                }
                goto PutCommit;
            }
            announce eWriterCrash, (id=id, phase=3);
            send parent, eWriterDone, (acked=false, id=id, hash=hash);
            raise halt;
        }
    }

    state PutCommit {
        entry {
            if (crashMode == 4) {
                goto ReconcileCommit;
            }
            res = uploadBlob(this, store, commitKey(id), blob);
            if (res.applied) {
                announce eCommitPut, (id=id, hash=hash);
            }
            if (res.ok) {
                if (crashMode == 2) {
                    announce eWriterCrash, (id=id, phase=2);
                    send parent, eWriterDone, (acked=false, id=id, hash=hash);
                    raise halt;
                }
                if (crashMode == 3) {
                    goto ReconcileCommit;
                }
                if (crashMode == 5) {
                    announce eWriterCrash, (id=id, phase=3);
                    send parent, eWriterDone, (acked=false, id=id, hash=hash);
                    raise halt;
                }
                goto Ack;
            }
            if (res.unknown) {
                goto ReconcileCommit;
            }
            assert false, format("commit PUT failed for {0}", id);
        }
    }

    state ReconcileCommit {
        entry {
            tries = 0;
            admitted = false;
            while (tries < 2 && !admitted) {
                admitted = admitThisPair(this, store, id, hash);
                tries = tries + 1;
            }
            if (admitted) {
                if (!res.applied) {
                    announce eCommitPut, (id=id, hash=hash);
                }
                goto Ack;
            }
            announce eWriterCrash, (id=id, phase=3);
            send parent, eWriterDone, (acked=false, id=id, hash=hash);
            raise halt;
        }
    }

    state Ack {
        entry {
            announce eIngestAck, (id=id, hash=hash);
            send parent, eWriterDone, (acked=true, id=id, hash=hash);
        }
    }
}
