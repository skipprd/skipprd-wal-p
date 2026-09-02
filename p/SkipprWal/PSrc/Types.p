// Skippr S3 WAL protocol events and helpers.
//
// Not an LSN log. Segment ids are opaque ints (stand-ins for random
// snapshot ids). Ownership is the bound pair {id}.seg + {id}.seg.commit.
// One logical flush (payload hash) owns at most one id. Offset keys in
// the blob are source objects Closed after ACK or Recover admit.

type tBlob = (id: int, hash: int, offs: seq[int]);
type tPutResult = (ok: bool, unknown: bool, applied: bool);

event eAppendStart: (id: int, hash: int);
event eBodyPut: (id: int, hash: int);
event eCommitPut: (id: int, hash: int);
event eIngestAck: (id: int, hash: int);
event eWriterCrash: (id: int, phase: int);
event eWriterDone: (acked: bool, id: int, hash: int);

event eSubmit: (key: int);
event eIngestSkip: (key: int);
event eOffsetsClosed: (key: int);
event eFlushTaken: (id: int, hash: int, offs: seq[int]);
event eIngestSubmit: (key: int);
event eIngestFlush: (crashMode: int, hash: int, restoreBad: bool);
event eIngestCoreDone: (acked: bool, id: int, hash: int);

event eRecoverStart;
event eRecoverAdmit: (id: int, bodyHash: int, commitHash: int);
event eRecoverSkip: (id: int, reason: int);
event eRecoverDone;

event eApplied: (id: int);
event eCommitDeleted: (id: int);
event eBodyDeleted: (id: int);
event eApplyGcDone: (id: int, crashed: bool);

event eScenarioDone;

// crashMode / phase: 0 none, 1 after body PUT, 2 after commit PUT before ACK,
//   3 commit observed; GET-admit this id then ACK (timeout reconcile),
//   4 skip commit PUT; GET miss; panic (commit never landed),
//   5 commit PUT done; skip GET; panic (GET unknown after backoff)
// recover skip reason: 0 orphan (body, no commit), 1 commit-only, 2 bind fail
// reconcile GET attempts before panic (stand-in for exp backoff)

fun emptyKeys(): seq[int] {
    return default(seq[int]);
}

fun emptyBlob(): tBlob {
    return (id=0, hash=0, offs=emptyKeys());
}

fun bodyKey(id: int): string {
    return format("{0}.seg", id);
}

fun commitKey(id: int): string {
    return format("{0}.seg.commit", id);
}

fun uploadBlob(sender: machine, store: ObjectStore, key: string, blob: tBlob): tPutResult {
    var ok: bool;
    var unknown: bool;
    var applied: bool;
    ok = false;
    unknown = false;
    applied = false;
    send store, eUploadRequest, (sender=sender, key=key, value=blob, expected_version=-1);
    receive {
        case eUploadResponse: (response: tUploadResponse) {
            ok = response.success;
            unknown = response.unknown;
            applied = response.applied;
        }
    }
    return (ok=ok, unknown=unknown, applied=applied);
}

fun downloadBlob(sender: machine, store: ObjectStore, key: string): (found: bool, blob: tBlob) {
    var found: bool;
    var blob: tBlob;
    found = false;
    blob = emptyBlob();
    send store, eDownloadRequest, (sender=sender, key=key);
    receive {
        case eDownloadResponse: (response: tDownloadResponse) {
            if (response.success) {
                found = true;
                blob = response.value as tBlob;
            }
        }
    }
    return (found=found, blob=blob);
}

fun admitThisPair(sender: machine, store: ObjectStore, id: int, hash: int): bool {
    var body: (found: bool, blob: tBlob);
    var commit: (found: bool, blob: tBlob);
    body = downloadBlob(sender, store, bodyKey(id));
    commit = downloadBlob(sender, store, commitKey(id));
    if (body.found && commit.found) {
        if (body.blob.hash == hash && commit.blob.hash == hash && body.blob.id == id && commit.blob.id == id && body.blob.hash == commit.blob.hash) {
            return true;
        }
    }
    return false;
}

fun bodyPresent(sender: machine, store: ObjectStore, id: int, hash: int): bool {
    var body: (found: bool, blob: tBlob);
    body = downloadBlob(sender, store, bodyKey(id));
    if (body.found && body.blob.id == id && body.blob.hash == hash) {
        return true;
    }
    return false;
}

fun publishClosedKeys(parent: machine, offs: seq[int]) {
    var i: int;
    var k: int;
    i = 0;
    while (i < sizeof(offs)) {
        k = offs[i];
        announce eOffsetsClosed, (key=k,);
        send parent, eOffsetsClosed, (key=k,);
        i = i + 1;
    }
}

fun waitRecover() {
    var done: bool;
    done = false;
    while (!done) {
        receive {
            case eOffsetsClosed: (payload: (key: int)) {}
            case eRecoverDone: {
                done = true;
            }
        }
    }
}

fun deleteKey(sender: machine, store: ObjectStore, key: string) {
    send store, eDeleteRequest, (sender=sender, key=key);
    receive {
        case eDeleteResponse: (response: tDeleteResponse) {}
    }
}

fun listKeys(sender: machine, store: ObjectStore): seq[string] {
    var ks: seq[string];
    send store, eListRequest, (sender=sender, prefix="");
    receive {
        case eListResponse: (response: tListResponse) {
            ks = response.keyList;
        }
    }
    return ks;
}
