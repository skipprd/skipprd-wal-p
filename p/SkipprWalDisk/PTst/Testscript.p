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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskApplyGc, DiskScenario, SingleWriterNoCrash };

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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskApplyGc, DiskScenario, CrashAfterBodyBeforeCommit };

test crashAfterPreparedBeforeCommitted [main=CrashAfterPreparedBeforeCommitted]:
    assert LivenessAppendCloses
        , SafetyAckImpliesOwned
        , SafetyOrphanNeverOwned
        , SafetyBindRequired
        , SafetyReclaimUnowns
        , SafetyOwnedMonotoneUntilGc
        , SafetyOneFlushOneId
        , SafetyIngestWorkClosed
        , SafetyFlushAtomic
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskApplyGc, DiskScenario, CrashAfterPreparedBeforeCommitted };

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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskApplyGc, DiskScenario, CrashAfterCommitBeforeAck };

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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskApplyGc, DiskScenario, CrashAfterCommitDeleteBeforeBody };

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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskApplyGc, DiskScenario, GcHole };

// Expected to fail SafetyAckImpliesOwned (two writers, same id).
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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskApplyGc, DiskScenario, DualWriter };

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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskIngestCore, FlushAtomicTwoKeys };

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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskIngestCore, SourceRetryAfterPanic };

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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskIngestCore, TimeoutReconcileCloses };

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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskIngestCore, CommitNeverLandedSourceRetry };

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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskIngestCore, TwoFlushesTwoUnits };

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
    in { DiskStore, MutationLog, DiskWriter, DiskRecover, DiskIngestCore, RestoreLiveNewId };
