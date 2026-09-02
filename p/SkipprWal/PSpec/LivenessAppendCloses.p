/// Liveness: every append attempt eventually ACKs or the writer crashes
/// (source still holds; not owned). Crash is a cold outcome.
spec LivenessAppendCloses observes eAppendStart, eIngestAck, eWriterCrash {
    var nOpen: int;

    start state Init {
        entry {
            nOpen = 0;
            goto Idle;
        }
    }

    hot state Inflight {
        on eAppendStart do (payload: (id: int, hash: int)) {
            nOpen = nOpen + 1;
        }

        on eIngestAck do (payload: (id: int, hash: int)) {
            nOpen = nOpen - 1;
            if (nOpen == 0) {
                goto Idle;
            }
        }

        on eWriterCrash do (payload: (id: int, phase: int)) {
            nOpen = nOpen - 1;
            if (nOpen == 0) {
                goto Idle;
            }
        }
    }

    cold state Idle {
        on eAppendStart do (payload: (id: int, hash: int)) {
            nOpen = nOpen + 1;
            goto Inflight;
        }

        on eIngestAck do (payload: (id: int, hash: int)) {
            assert false, "ACK with no in-flight append";
        }

        on eWriterCrash do (payload: (id: int, phase: int)) {
            assert false, "crash with no in-flight append";
        }
    }
}
