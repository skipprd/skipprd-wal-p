# P projects

Formal models for Skippr ingest WAL. See the [P website](https://p-org.github.io/P) for the language and tools.

Layout follows [OSWALD](https://github.com/nvartolomei/oswald/tree/main/p) (`Store` ≈ `ObjectStore` / `DiskStore`, `SkipprWal` / `SkipprWalDisk` ≈ `Oswald`). Safety specs are Skippr pair-ownership, not LSN prefix consistency.

| Project | Backend |
|---------|---------|
| `SkipprWal/` | S3 object PUT pair-commit |
| `SkipprWalDisk/` | Disk sync store + mutation log |

## Cheat sheet

```sh
cd SkipprWal
p compile
../../scripts/check-s3.sh

cd ../SkipprWalDisk
p compile
../../scripts/check-disk.sh

# One test, 1000 schedules:
p check --testcase singleWriterNoCrash --schedules 1000

# 10 seeds in parallel (needs GNU parallel):
seq 10 | parallel --tag --line-buffer --color --halt now,fail=1 \
    p check --testcase gcHole --schedules 1000 --outdir PCheckerOutput/{}
```

Install P: [p-org.github.io/P/getstarted/install](https://p-org.github.io/P/getstarted/install/) — typically `dotnet tool install -g P`. If the SDK is in `~/.dotnet`, export `DOTNET_ROOT=$HOME/.dotnet`.

`dualWriter` is expected to fail (`SafetyAckImpliesOwned`). It documents that two processes writing one pipeline are unsupported.

`retryNewId` and `restoreLiveNewId` are expected to fail (`SafetyOneFlushOneId`). A persist timeout must GET-admit this id or panic; it must not restore live bytes or mint a second snapshot id for the same payload.

Ingest Closed and flush atomicity (`SafetyIngestWorkClosed`, `SafetyFlushAtomic`) apply to both S3 and disk. See the root README.
