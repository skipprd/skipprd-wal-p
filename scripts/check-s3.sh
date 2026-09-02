#!/usr/bin/env bash
# Single-writer S3 suite. dualWriter, retryNewId, and restoreLiveNewId are
# expected to fail and are not run here.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/p/SkipprWal"

# User-local SDK from dotnet-install.sh
if [ -d "$HOME/.dotnet" ]; then
    export DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"
    export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"
fi

p compile

SCHEDULES="${SCHEDULES:-1000}"

for tc in \
    singleWriterNoCrash \
    crashAfterBodyBeforeCommit \
    crashAfterCommitBeforeAck \
    crashAfterCommitDeleteBeforeBody \
    gcHole \
    timeoutReconcileAck \
    timeoutCommitNeverLanded \
    timeoutGetUnknownPanic \
    timeoutLossyPuts \
    flushAtomicTwoKeys \
    sourceRetryAfterPanic \
    timeoutReconcileCloses \
    commitNeverLandedSourceRetry \
    twoFlushesTwoUnits
do
    echo "=== $tc ($SCHEDULES schedules) ==="
    p check --testcase "$tc" --schedules "$SCHEDULES"
done

echo "single-writer suite passed"
