// Durable mutation log: Prepared → Committed → Applied.
// Pair scan is not authority; only Applied CommitSegment records admit.

type tSegmentEntry = (id: int, hash: int);

event eLogPrepareRequest: (sender: machine, id: int, hash: int);
event eLogPrepareResponse: (success: bool);

event eLogCommitRequest: (sender: machine, id: int, hash: int);
event eLogCommitResponse: (success: bool);

event eLogApplyRequest: (sender: machine, id: int, hash: int);
event eLogApplyResponse: (success: bool);

event eLogReclaimRequest: (sender: machine, id: int);
event eLogReclaimResponse: (success: bool);

event eLogQueryAppliedRequest: (sender: machine);
event eLogQueryAppliedResponse: (entries: seq[tSegmentEntry]);

event eLogAbandonPreparedRequest: (sender: machine);
event eLogAbandonPreparedResponse: (success: bool);

machine MutationLog {
    var preparedId: int;
    var preparedHash: int;
    var hasPrepared: bool;
    var applied: seq[tSegmentEntry];
    var nextIndex: int;

    start state Init {
        entry {
            preparedId = -1;
            preparedHash = 0;
            hasPrepared = false;
            applied = default(seq[tSegmentEntry]);
            nextIndex = 0;
        }

        on eLogPrepareRequest do (payload: (sender: machine, id: int, hash: int)) {
            assert !hasPrepared, "mutation log already has Prepared";
            preparedId = payload.id;
            preparedHash = payload.hash;
            hasPrepared = true;
            send payload.sender, eLogPrepareResponse, (success=true,);
        }

        on eLogCommitRequest do (payload: (sender: machine, id: int, hash: int)) {
            assert hasPrepared, "commit without Prepared";
            assert preparedId == payload.id, "commit id mismatch";
            assert preparedHash == payload.hash, "commit hash mismatch";
            hasPrepared = false;
            nextIndex = nextIndex + 1;
            send payload.sender, eLogCommitResponse, (success=true,);
        }

        on eLogApplyRequest do (payload: (sender: machine, id: int, hash: int)) {
            applied += (sizeof(applied), (id=payload.id, hash=payload.hash));
            send payload.sender, eLogApplyResponse, (success=true,);
        }

        on eLogReclaimRequest do (payload: (sender: machine, id: int)) {
            applied += (sizeof(applied), (id=payload.id, hash=0));
            send payload.sender, eLogReclaimResponse, (success=true,);
        }

        on eLogQueryAppliedRequest do (payload: (sender: machine)) {
            send payload.sender, eLogQueryAppliedResponse, (entries=applied,);
        }

        on eLogAbandonPreparedRequest do (payload: (sender: machine)) {
            hasPrepared = false;
            preparedId = -1;
            preparedHash = 0;
            send payload.sender, eLogAbandonPreparedResponse, (success=true,);
        }
    }
}

fun logPrepare(sender: machine, log: MutationLog, id: int, hash: int) {
    send log, eLogPrepareRequest, (sender=sender, id=id, hash=hash);
    receive {
        case eLogPrepareResponse: (response: (success: bool)) {
            assert response.success, "log prepare failed";
        }
    }
}

fun logCommit(sender: machine, log: MutationLog, id: int, hash: int) {
    send log, eLogCommitRequest, (sender=sender, id=id, hash=hash);
    receive {
        case eLogCommitResponse: (response: (success: bool)) {
            assert response.success, "log commit failed";
        }
    }
}

fun logApply(sender: machine, log: MutationLog, id: int, hash: int) {
    send log, eLogApplyRequest, (sender=sender, id=id, hash=hash);
    receive {
        case eLogApplyResponse: (response: (success: bool)) {
            assert response.success, "log apply failed";
        }
    }
}

fun logReclaim(sender: machine, log: MutationLog, id: int) {
    send log, eLogReclaimRequest, (sender=sender, id=id);
    receive {
        case eLogReclaimResponse: (response: (success: bool)) {
            assert response.success, "log reclaim failed";
        }
    }
}

fun queryApplied(sender: machine, log: MutationLog): seq[tSegmentEntry] {
    var entries: seq[tSegmentEntry];
    send log, eLogQueryAppliedRequest, (sender=sender,);
    receive {
        case eLogQueryAppliedResponse: (response: (entries: seq[tSegmentEntry])) {
            entries = response.entries;
        }
    }
    return entries;
}

fun logAbandonPrepared(sender: machine, log: MutationLog) {
    send log, eLogAbandonPreparedRequest, (sender=sender,);
    receive {
        case eLogAbandonPreparedResponse: (response: (success: bool)) {
            assert response.success, "log abandon prepared failed";
        }
    }
}
