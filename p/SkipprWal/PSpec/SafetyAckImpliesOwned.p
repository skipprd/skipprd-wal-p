/// Safety: ACK requires a live, bound pair. The pair must keep binding
/// for every id that has been ACKed and not reclaimed (catches dual-writer
/// overwrite after ACK).
spec SafetyAckImpliesOwned observes eBodyPut, eCommitPut, eCommitDeleted, eBodyDeleted, eIngestAck {
    var bodyHash: map[int, int];
    var commitHash: map[int, int];
    var ackedHash: map[int, int];

    start state Observing {
        entry {}

        on eBodyPut do (payload: (id: int, hash: int)) {
            bodyHash[payload.id] = payload.hash;
            assertAckedStillBound();
        }

        on eCommitPut do (payload: (id: int, hash: int)) {
            commitHash[payload.id] = payload.hash;
            assertAckedStillBound();
        }

        on eCommitDeleted do (payload: (id: int)) {
            if (payload.id in commitHash) {
                commitHash -= (payload.id);
            }
            if (payload.id in ackedHash) {
                ackedHash -= (payload.id);
            }
        }

        on eBodyDeleted do (payload: (id: int)) {
            if (payload.id in bodyHash) {
                bodyHash -= (payload.id);
            }
        }

        on eIngestAck do (payload: (id: int, hash: int)) {
            assert payload.id in bodyHash, format("ACK {0} without body", payload.id);
            assert payload.id in commitHash, format("ACK {0} without commit", payload.id);
            assert bodyHash[payload.id] == commitHash[payload.id],
                format("ACK {0} unbound pair", payload.id);
            assert bodyHash[payload.id] == payload.hash,
                format("ACK {0} hash mismatch", payload.id);
            ackedHash[payload.id] = payload.hash;
            assertAckedStillBound();
        }
    }

    fun assertAckedStillBound() {
        var ids: seq[int];
        var i: int;
        var k: int;
        ids = keys(ackedHash);
        i = 0;
        while (i < sizeof(ids)) {
            k = ids[i];
            assert k in bodyHash, format("acked id {0} lost body", k);
            assert k in commitHash, format("acked id {0} lost commit", k);
            assert bodyHash[k] == commitHash[k], format("acked id {0} no longer binds", k);
            assert bodyHash[k] == ackedHash[k], format("acked id {0} overwritten", k);
            i = i + 1;
        }
    }
}
