/// Safety: keys taken together belong to one snapshot id until reclaim.
/// A key must not sit in two in-flight hashes. After Recover, leftover
/// in-flight keys are abandoned (persist never admitted) and may be
/// taken again. Restore-live + new id takes the same keys while the
/// first take is still in-flight and fails this spec.

spec SafetyFlushAtomic observes eFlushTaken, eOffsetsClosed, eRecoverDone, eCommitDeleted {
    var inFlight: map[int, int];
    var live: map[int, int];
    var keysOfId: map[int, seq[int]];

    start state Observing {
        entry {}

        on eFlushTaken do (payload: (id: int, hash: int, offs: seq[int])) {
            var i: int;
            var k: int;
            i = 0;
            while (i < sizeof(payload.offs)) {
                k = payload.offs[i];
                if (k in live) {
                    assert live[k] == payload.id,
                        format("offset key {0} live on id {1} taken again by id {2}", k, live[k], payload.id);
                }
                if (k in inFlight) {
                    assert inFlight[k] == payload.id,
                        format("offset key {0} in-flight on id {1} and id {2}", k, inFlight[k], payload.id);
                }
                inFlight[k] = payload.id;
                i = i + 1;
            }
            keysOfId[payload.id] = payload.offs;
        }

        on eOffsetsClosed do (payload: (key: int)) {
            if (payload.key in inFlight) {
                live[payload.key] = inFlight[payload.key];
                inFlight -= (payload.key);
            }
        }

        on eRecoverDone do {
            var leftover: seq[int];
            var i: int;
            var k: int;
            leftover = keys(inFlight);
            i = 0;
            while (i < sizeof(leftover)) {
                k = leftover[i];
                inFlight -= (k);
                i = i + 1;
            }
        }

        on eCommitDeleted do (payload: (id: int)) {
            var ks: seq[int];
            var i: int;
            var k: int;
            if (payload.id in keysOfId) {
                ks = keysOfId[payload.id];
                i = 0;
                while (i < sizeof(ks)) {
                    k = ks[i];
                    if (k in live && live[k] == payload.id) {
                        live -= (k);
                    }
                    if (k in inFlight && inFlight[k] == payload.id) {
                        inFlight -= (k);
                    }
                    i = i + 1;
                }
                keysOfId -= (payload.id);
            }
        }
    }
}
