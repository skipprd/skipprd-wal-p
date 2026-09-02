/// Safety: without reclaim, the recovered owned set only grows.
/// Reclaim may punch a hole: that id is dropped from the baseline so
/// gcHole is allowed (this is not an LSN prefix property).
spec SafetyOwnedMonotoneUntilGc observes eRecoverStart, eRecoverAdmit, eRecoverDone, eCommitDeleted {
    var baseline: map[int, bool];
    var current: map[int, bool];
    var hasBaseline: bool;

    start state Observing {
        entry {
            hasBaseline = false;
        }

        on eCommitDeleted do (payload: (id: int)) {
            if (payload.id in baseline) {
                baseline -= (payload.id);
            }
            if (payload.id in current) {
                current -= (payload.id);
            }
        }

        on eRecoverStart do {
            current = default(map[int, bool]);
        }

        on eRecoverAdmit do (payload: (id: int, bodyHash: int, commitHash: int)) {
            current[payload.id] = true;
        }

        on eRecoverDone do {
            var ids: seq[int];
            var i: int;
            var k: int;
            if (hasBaseline) {
                ids = keys(baseline);
                i = 0;
                while (i < sizeof(ids)) {
                    k = ids[i];
                    assert k in current,
                        format("owned id {0} disappeared without reclaim", k);
                    i = i + 1;
                }
            }
            baseline = current;
            hasBaseline = true;
        }
    }
}
