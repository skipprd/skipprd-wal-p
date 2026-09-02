/// Safety: recovery never admits a body-only orphan (or commit-only).
spec SafetyOrphanNeverOwned observes eBodyPut, eCommitPut, eCommitDeleted, eBodyDeleted, eRecoverAdmit {
    var hasBody: map[int, bool];
    var hasCommit: map[int, bool];

    start state Observing {
        entry {}

        on eBodyPut do (payload: (id: int, hash: int)) {
            hasBody[payload.id] = true;
        }

        on eCommitPut do (payload: (id: int, hash: int)) {
            hasCommit[payload.id] = true;
        }

        on eCommitDeleted do (payload: (id: int)) {
            if (payload.id in hasCommit) {
                hasCommit -= (payload.id);
            }
        }

        on eBodyDeleted do (payload: (id: int)) {
            if (payload.id in hasBody) {
                hasBody -= (payload.id);
            }
        }

        on eRecoverAdmit do (payload: (id: int, bodyHash: int, commitHash: int)) {
            assert payload.id in hasBody, format("admitted {0} without body", payload.id);
            assert payload.id in hasCommit, format("admitted {0} without commit (orphan or commit-only)", payload.id);
        }
    }
}
