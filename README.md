# skipprd-wal-p

[![Check](https://github.com/skipprd/skipprd-wal-p/actions/workflows/check.yml/badge.svg)](https://github.com/skipprd/skipprd-wal-p/actions/workflows/check.yml)

P specification of Skippr's ingest write-ahead log. This is the protocol spec for skipprd ELT WAL backends. It checks pair-ownership, ACK-after-commit, ingest Closed, flush atomicity, orphan ignore, reclaim order, and crash windows. Skippr WAL (S3 and Disk) is intended to support a single writer, read-after-write commit boundary, for use in the [skipprd ELT CLI tool](https://skippr.io/elt/getting-started/quickstart). Licensed under [Elastic License 2.0](LICENSE). OSWALD ObjectStore remains MIT; see [NOTICE](NOTICE).

[OSWALD](https://github.com/nvartolomei/oswald) is the **scaffold** (P layout + `ObjectStore`). The invariants are Skippr's: random segment ids (I know... I was surprised I got away with it), two-object commit, GC that may leave holes after apply. There is no LSN, no manifest, no prefix-consistency check.

## Status

| Backend | In this repo |
|---------|----------------|
| **S3** (`WAL_STORAGE=s3`) | Modeled. `p check` green on the single-writer suite. |
| **Disk** (`WAL_STORAGE=disk`) | Modeled. `p check` green on the single-writer suite in `p/SkipprWalDisk/`. |
| **Clustered** (`WAL_STORAGE=clustered`) | @todo |

## S3 model

Writer: unconditional PUT `{id}.seg`, then PUT `{id}.seg.commit`, then ACK. If a PUT returns unknown, GET-admit **this** id (same bind as recovery): bound pair → ACK that id; GET miss after retries → panic, no new snapshot. Recover: List, then GET each id; admit iff both exist and hashes bind. ApplyGc: delete commit first, then body.

Safety specs:

- `SafetyAckImpliesOwned` — ACK requires a live bound pair; ACKed ids must keep binding until reclaim
- `SafetyOrphanNeverOwned` — body without commit is never admitted
- `SafetyBindRequired` — admit ⇒ body hash == commit hash
- `SafetyReclaimUnowns` — commit delete un-owns; leftover body is an orphan
- `SafetyOwnedMonotoneUntilGc` — without reclaim the owned set only grows; **holes after apply are allowed**
- `SafetyOneFlushOneId` — one payload hash owns at most one segment id (timeout must not mint a second snapshot)
- `SafetyIngestWorkClosed` — after ACK or Recover admit, a later submit of that offset key is skip, never a new flush
- `SafetyFlushAtomic` — keys taken together belong to one snapshot id until reclaim; a key is never in two in-flight hashes
- `LivenessAppendCloses` — each append ACKs or the writer crashes (source still holds)

`dualWriter` (same id, two proposers) is **expected to fail** `SafetyAckImpliesOwned`. `retryNewId` (same payload, new id after a landed commit) is **expected to fail** `SafetyOneFlushOneId`. `restoreLiveNewId` (put taken keys back in live and persist a new id) is **expected to fail** `SafetyFlushAtomic` (and `SafetyOneFlushOneId` if the second persist lands).

## Build and check

CI runs `./scripts/check-s3.sh` and `./scripts/check-disk.sh` on every push and pull request (single-writer suites; not `dualWriter`, `retryNewId`, or `restoreLiveNewId`). Jobs use [Skippr Cloud Deploy Runners](https://skippr.io/cloud/deploy/runner); bind the repo with Terraform in [`terraform/deploy-runner/`](terraform/deploy-runner/).

Requires the [P compiler](https://p-org.github.io/P/getstarted/install/) (`dotnet tool install -g P`) and .NET SDK 8. If the SDK lives in `~/.dotnet`, export `DOTNET_ROOT=$HOME/.dotnet` and put `$HOME/.dotnet` plus `$HOME/.dotnet/tools` on `PATH`.

```sh
cd p/SkipprWal
p compile

# Single-writer S3 suite (must pass):
./../../scripts/check-s3.sh

# Single-writer disk suite (must pass):
./../../scripts/check-disk.sh

# Or one testcase:
p check --testcase gcHole --schedules 1000

# Expected fail (dual writer / no fencing):
p check --testcase dualWriter --schedules 100

# Expected fail (timeout treated as failure + new snapshot id):
p check --testcase retryNewId --schedules 100

# Expected fail (restore live + new id after a landed commit):
p check --testcase restoreLiveNewId --schedules 100
```

From `p/` you can also follow OSWALD's parallel checker pattern:

```sh
p compile
seq 10 | parallel --tag --line-buffer --color --halt now,fail=1 \
    p check --testcase singleWriterNoCrash --schedules 1000 --outdir PCheckerOutput/{}
```

## Disk model

`DiskStore` buffers writes until `Sync` (fdatasync + dir fsync). Writer: sync body → log **Prepared** → **Committed** → Apply writes `{id}.seg.commit` → ACK. Recover admits only ids recorded as **Applied** in the mutation log; orphan bodies and pair-only scans are skipped. Reclaim goes through the log like production.

Extra disk testcase: `crashAfterPreparedBeforeCommitted` (Prepared without Committed must not own).

```sh
cd p/SkipprWalDisk
p compile
./../../scripts/check-disk.sh
```

## Clustered (later)

Disk protocol plus:

- `LeaseStore` with CAS (clock-free steal after the observe window)
- Replica: local fsynced Prepared + one remote Ack (RF=2, WRITE_QUORUM=2)
- Timeout keeps Prepared and fences ingest (`UnprovenPrepared`)
- Peer with the same index+hash can finalize commit on promote
- Stale epoch Nack; same-index different hash ⇒ Diverged

Check runs on [Skippr Cloud Deploy Runners](https://skippr.io/cloud/deploy/runner).

## Timeout reconcile

A commit PUT timeout is not a failed persist. The writer GETs this snapshot's pair and binds it the same way recovery does. If the pair is there, ACK that id, mark the flush done, and do not mint another snapshot. If GET still misses after retries, panic: this process must not restore live bytes or start a second id for the same coalesced payload. Restart recovery admits the pair if it landed.

The previous hole was: commit object exists, client sees unknown, next flush uses a new random id, recovery owns both. Coalesced segments are not row-idempotent, so that is a duplicate owned set. `SafetyOneFlushOneId` is that invariant. `timeoutReconcileAck`, `timeoutCommitNeverLanded`, `timeoutGetUnknownPanic`, and `timeoutLossyPuts` check the close-out; `retryNewId` and `restoreLiveNewId` are discarded paths and are expected to fail.

## Ingest Closed and flush atomicity

Same rules on **S3 and disk**. Durability underneath stays per backend (S3 two-object PUT; disk sync + mutation log). Admit, Closed, take-all flush, and no restore-live are shared.

- Offset keys are source objects stored in both pair objects so Recover can replay Closed.
- Submit of a Closed key is skip: it must not append to live or start a new persist.
- Flush `take()`s **all** live keys into one snapshot id. Two units submitted before one flush share that id. A unit is never split across two ids.
- Persist success or Recover admit publishes Closed, then the source may ACK. Unknown persist after retries panics. Do not put the taken keys back in live. Do not mint a new id.
- Disk unknown is a log/fsync crash, not HTTP GET. Same ingest rule: panic, Recover from Applied log, Closed from admitted keys.

`flushAtomicTwoKeys`, `sourceRetryAfterPanic`, `timeoutReconcileCloses`, `commitNeverLandedSourceRetry`, and `twoFlushesTwoUnits` cover this path on both backends.
