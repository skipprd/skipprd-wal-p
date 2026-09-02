/// Safety: a Closed offset key must not appear in a later flush.
spec SafetyIngestWorkClosed observes eOffsetsClosed, eFlushTaken {
    var closed: map[int, bool];

    start state Observing {
        entry {}

        on eOffsetsClosed do (payload: (key: int)) {
            closed[payload.key] = true;
        }

        on eFlushTaken do (payload: (id: int, hash: int, offs: seq[int])) {
            var i: int;
            var k: int;
            i = 0;
            while (i < sizeof(payload.offs)) {
                k = payload.offs[i];
                assert !(k in closed),
                    format("flush id {0} includes Closed offset key {1}", payload.id, k);
                i = i + 1;
            }
        }
    }
}
