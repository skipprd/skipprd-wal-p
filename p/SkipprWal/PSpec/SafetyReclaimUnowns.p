/// Safety: deleting the commit un-owns. Later recovery must not admit
/// that id until a new commit PUT (leftover body is an orphan).
spec SafetyReclaimUnowns observes eCommitPut, eCommitDeleted, eRecoverAdmit {
    var liveCommit: map[int, bool];

    start state Observing {
        entry {}

        on eCommitPut do (payload: (id: int, hash: int)) {
            liveCommit[payload.id] = true;
        }

        on eCommitDeleted do (payload: (id: int)) {
            if (payload.id in liveCommit) {
                liveCommit -= (payload.id);
            }
        }

        on eRecoverAdmit do (payload: (id: int, bodyHash: int, commitHash: int)) {
            assert payload.id in liveCommit,
                format("admitted {0} after commit delete (reclaim must un-own)", payload.id);
        }
    }
}
