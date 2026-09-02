// Skippr disk WAL protocol events and helpers.
//
// Same pair-ownership surface as the S3 model, but commit markers are
// written only by Apply after the mutation log records Prepared → Committed.
// Recovery admits from the log, not from a blind pair scan.

type tBlob = (id: int, hash: int, offs: seq[int]);

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

// crashMode: 0 none, 1 after body sync, 2 after prepared, 3 after committed
//            before apply, 4 after commit put before ACK
// recover skip reason: 0 orphan body, 1 commit-only, 2 bind fail, 3 not in log

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

fun diskWrite(sender: machine, store: DiskStore, key: string, value: data) {
    send store, eDiskWriteRequest, (sender=sender, key=key, value=value);
    receive {
        case eDiskWriteResponse: (response: (success: bool)) {
            assert response.success, format("disk write failed for {0}", key);
        }
    }
}

fun diskSync(sender: machine, store: DiskStore) {
    send store, eDiskSyncRequest, (sender=sender,);
    receive {
        case eDiskSyncResponse: (response: (success: bool)) {
            assert response.success, "disk sync failed";
        }
    }
}

fun diskPutSynced(sender: machine, store: DiskStore, key: string, blob: tBlob) {
    diskWrite(sender, store, key, blob as data);
    diskSync(sender, store);
}

fun diskReadBlob(sender: machine, store: DiskStore, key: string): (found: bool, blob: tBlob) {
    var found: bool;
    var blob: tBlob;
    found = false;
    blob = emptyBlob();
    send store, eDiskReadRequest, (sender=sender, key=key);
    receive {
        case eDiskReadResponse: (response: (success: bool, value: data)) {
            if (response.success) {
                found = true;
                blob = response.value as tBlob;
            }
        }
    }
    return (found=found, blob=blob);
}

fun diskDeleteSynced(sender: machine, store: DiskStore, key: string) {
    send store, eDiskDeleteRequest, (sender=sender, key=key);
    receive {
        case eDiskDeleteResponse: (response: (success: bool)) {}
    }
    diskSync(sender, store);
}

fun listKeys(sender: machine, store: DiskStore): seq[string] {
    var ks: seq[string];
    send store, eDiskListRequest, (sender=sender, prefix="");
    receive {
        case eDiskListResponse: (response: (keyList: seq[string])) {
            ks = response.keyList;
        }
    }
    return ks;
}
