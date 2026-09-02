/// Safety: one logical flush (payload hash) owns at most one segment id.
/// Timeout-then-new-id for the same coalesced payload violates this;
/// GET-admit this id, or panic and Recover, does not.

spec SafetyOneFlushOneId observes eCommitPut, eCommitDeleted {
    var hashOfId: map[int, int];
    var idOfHash: map[int, int];

    start state Observing {
        entry {}

        on eCommitPut do (payload: (id: int, hash: int)) {
            var oldHash: int;
            if (payload.id in hashOfId) {
                oldHash = hashOfId[payload.id];
                if (oldHash != payload.hash) {
                    if (oldHash in idOfHash && idOfHash[oldHash] == payload.id) {
                        idOfHash -= (oldHash);
                    }
                }
            }
            if (payload.hash in idOfHash) {
                assert idOfHash[payload.hash] == payload.id,
                    format("flush hash {0} owned by id {1} and id {2}",
                        payload.hash, idOfHash[payload.hash], payload.id);
            }
            hashOfId[payload.id] = payload.hash;
            idOfHash[payload.hash] = payload.id;
        }

        on eCommitDeleted do (payload: (id: int)) {
            var h: int;
            if (payload.id in hashOfId) {
                h = hashOfId[payload.id];
                hashOfId -= (payload.id);
                if (h in idOfHash && idOfHash[h] == payload.id) {
                    idOfHash -= (h);
                }
            }
        }
    }
}
