// Apply then reclaim: delete commit first (un-own), then body.
// crashAfterCommitDelete: halt after the commit object is gone (orphan body).

machine ApplyGc {
    var parent: machine;
    var store: ObjectStore;
    var id: int;
    var crashAfterCommitDelete: bool;

    start state Init {
        entry (input: (parent: machine, store: ObjectStore, id: int, crashAfterCommitDelete: bool)) {
            parent = input.parent;
            store = input.store;
            id = input.id;
            crashAfterCommitDelete = input.crashAfterCommitDelete;
            announce eApplied, (id=id,);
            goto DeleteCommit;
        }
    }

    state DeleteCommit {
        entry {
            deleteKey(this, store, commitKey(id));
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
            deleteKey(this, store, bodyKey(id));
            announce eBodyDeleted, (id=id,);
            send parent, eApplyGcDone, (id=id, crashed=false);
        }
    }
}
