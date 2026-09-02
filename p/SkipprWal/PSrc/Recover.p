// Recovery: List (interleaves with PUTs), then GET each id in [0, maxId).
// Admit iff both objects exist and hashes bind. Orphans and commit-only
// keys are skipped. Bounded ids stand in for listing + suffix filter.

machine Recover {
    var parent: machine;
    var store: ObjectStore;
    var maxId: int;
    var id: int;
    var listed: seq[string];
    var body: (found: bool, blob: tBlob);
    var commit: (found: bool, blob: tBlob);

    start state Init {
        entry (input: (parent: machine, store: ObjectStore, maxId: int)) {
            parent = input.parent;
            store = input.store;
            maxId = input.maxId;
            announce eRecoverStart;
            listed = listKeys(this, store);
            print format("recover listed {0} keys", sizeof(listed));
            id = 0;
            goto Scan;
        }
    }

    state Scan {
        entry {
            while (id < maxId) {
                body = downloadBlob(this, store, bodyKey(id));
                commit = downloadBlob(this, store, commitKey(id));
                if (body.found && commit.found) {
                    if (body.blob.hash == commit.blob.hash && body.blob.id == id && commit.blob.id == id) {
                        announce eRecoverAdmit, (id=id, bodyHash=body.blob.hash, commitHash=commit.blob.hash);
                        publishClosedKeys(parent, commit.blob.offs);
                    } else {
                        announce eRecoverSkip, (id=id, reason=2);
                    }
                } else {
                    if (body.found && !commit.found) {
                        announce eRecoverSkip, (id=id, reason=0);
                    } else {
                        if (!body.found && commit.found) {
                            announce eRecoverSkip, (id=id, reason=1);
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
