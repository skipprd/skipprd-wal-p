// Apply then reclaim via the mutation log: delete commit first, then body.

machine DiskApplyGc {
    var parent: machine;
    var store: DiskStore;
    var log: MutationLog;
    var id: int;
    var crashAfterCommitDelete: bool;

    start state Init {
        entry (input: (parent: machine, store: DiskStore, log: MutationLog, id: int, crashAfterCommitDelete: bool)) {
            parent = input.parent;
            store = input.store;
            log = input.log;
            id = input.id;
            crashAfterCommitDelete = input.crashAfterCommitDelete;
            announce eApplied, (id=id,);
            goto LogReclaim;
        }
    }

    state LogReclaim {
        entry {
            logReclaim(this, log, id);
            goto DeleteCommit;
        }
    }

    state DeleteCommit {
        entry {
            diskDeleteSynced(this, store, commitKey(id));
            announce eCommitDeleted, (id=id,);
            if (crashAfterCommitDelete) {
                send parent, eApplyGcDone, (id=id, crashed=true);
                raise halt;
            }
            goto DeleteBody;
        }
    }

    state DeleteBody {
        entry {
            diskDeleteSynced(this, store, bodyKey(id));
            announce eBodyDeleted, (id=id,);
            send parent, eApplyGcDone, (id=id, crashed=false);
        }
    }
}
