test singleWriterNoCrash [main=SingleWriterNoCrash]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, ApplyGc, Scenario, SingleWriterNoCrash };

test crashAfterBodyBeforeCommit [main=CrashAfterBodyBeforeCommit]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, ApplyGc, Scenario, CrashAfterBodyBeforeCommit };

test crashAfterCommitBeforeAck [main=CrashAfterCommitBeforeAck]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, ApplyGc, Scenario, CrashAfterCommitBeforeAck };

test crashAfterCommitDeleteBeforeBody [main=CrashAfterCommitDeleteBeforeBody]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, ApplyGc, Scenario, CrashAfterCommitDeleteBeforeBody };

test gcHole [main=GcHole]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, ApplyGc, Scenario, GcHole };

test timeoutReconcileAck [main=TimeoutReconcileAck]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, ApplyGc, Scenario, TimeoutReconcileAck };

test timeoutCommitNeverLanded [main=TimeoutCommitNeverLanded]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, ApplyGc, Scenario, TimeoutCommitNeverLanded };

test timeoutGetUnknownPanic [main=TimeoutGetUnknownPanic]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, ApplyGc, Scenario, TimeoutGetUnknownPanic };

test timeoutLossyPuts [main=TimeoutLossyPuts]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, ApplyGc, Scenario, TimeoutLossyPuts };

// Expected to fail SafetyAckImpliesOwned (two writers, same id).
// Documents the product lock: WAL_STORAGE=s3 is not multi-master.
// Do not include in the single-writer CI suite.
test dualWriter [main=DualWriter]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, ApplyGc, Scenario, DualWriter };

// Expected to fail SafetyOneFlushOneId (same payload, new snapshot id).
// Documents the discarded timeout path: treat unknown persist as failure
// and mint another random id. Do not include in the single-writer CI suite.
test retryNewId [main=RetryNewId]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, ApplyGc, Scenario, RetryNewId };

test flushAtomicTwoKeys [main=FlushAtomicTwoKeys]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, IngestCore, FlushAtomicTwoKeys };

test sourceRetryAfterPanic [main=SourceRetryAfterPanic]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, IngestCore, SourceRetryAfterPanic };

test timeoutReconcileCloses [main=TimeoutReconcileCloses]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, IngestCore, TimeoutReconcileCloses };

test commitNeverLandedSourceRetry [main=CommitNeverLandedSourceRetry]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, IngestCore, CommitNeverLandedSourceRetry };

test twoFlushesTwoUnits [main=TwoFlushesTwoUnits]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, IngestCore, TwoFlushesTwoUnits };

// Expected to fail SafetyOneFlushOneId (and SafetyFlushAtomic): take, land
// commit, restore live, persist a new id with the same keys. Do not include
// in the single-writer CI suite.
test restoreLiveNewId [main=RestoreLiveNewId]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { ObjectStore, Writer, Recover, IngestCore, RestoreLiveNewId };
