// Recovery: admit only ids recorded as Applied in the mutation log.
// Orphan bodies and commit-only keys found by scan are skipped.

machine DiskRecover {
    var parent: machine;
    var store: DiskStore;
    var log: MutationLog;
    var maxId: int;
    var entries: seq[tSegmentEntry];
    var listed: seq[string];
    var id: int;
    var i: int;
    var segEntry: tSegmentEntry;
    var inLog: map[int, bool];
    var body: (found: bool, blob: tBlob);
    var commitGet: (found: bool, blob: tBlob);

    start state Init {
        entry (input: (parent: machine, store: DiskStore, log: MutationLog, maxId: int)) {
            parent = input.parent;
            store = input.store;
            log = input.log;
            maxId = input.maxId;
            announce eRecoverStart;
            logAbandonPrepared(this, log);
            entries = queryApplied(this, log);
            listed = listKeys(this, store);
            print format("recover listed {0} keys, log applied {1}", sizeof(listed), sizeof(entries));

            inLog = default(map[int, bool]);
            i = 0;
            while (i < sizeof(entries)) {
                segEntry = entries[i];
                if (segEntry.hash != 0) {
                    inLog[segEntry.id] = true;
                }
                i = i + 1;
            }

            i = 0;
            while (i < sizeof(entries)) {
                segEntry = entries[i];
                if (segEntry.hash != 0) {
                    body = diskReadBlob(this, store, bodyKey(segEntry.id));
                    commitGet = diskReadBlob(this, store, commitKey(segEntry.id));
                    if (body.found && commitGet.found) {
                        if (body.blob.hash == commitGet.blob.hash
                            && body.blob.id == segEntry.id
                            && commitGet.blob.id == segEntry.id
                            && body.blob.hash == segEntry.hash) {
                            announce eRecoverAdmit, (id=segEntry.id, bodyHash=body.blob.hash, commitHash=commitGet.blob.hash);
                            publishClosedKeys(parent, commitGet.blob.offs);
                        } else {
                            announce eRecoverSkip, (id=segEntry.id, reason=2);
                        }
                    } else {
                        announce eRecoverSkip, (id=segEntry.id, reason=2);
                    }
                }
                i = i + 1;
            }

            id = 0;
            goto ScanOrphans;
        }
    }

    state ScanOrphans {
        entry {
            while (id < maxId) {
                if (!(id in inLog)) {
                    body = diskReadBlob(this, store, bodyKey(id));
                    commitGet = diskReadBlob(this, store, commitKey(id));
                    if (body.found && !commitGet.found) {
                        announce eRecoverSkip, (id=id, reason=0);
                    } else {
                        if (!body.found && commitGet.found) {
                            announce eRecoverSkip, (id=id, reason=1);
                        } else {
                            if (body.found && commitGet.found) {
                                announce eRecoverSkip, (id=id, reason=3);
                            }
                        }
                    }
                }
                id = id + 1;
            }
            announce eRecoverDone;
            send parent, eRecoverDone;
        }
    }
}
