type tDiskScenarioConfig = (
    parent: machine,
    nSegments: int,
    crashMode: int,
    reclaimId: int,
    reclaimCrash: bool,
    dual: bool
);

machine DiskScenario {
    var parent: machine;
    var store: DiskStore;
    var log: MutationLog;
    var nSegments: int;
    var crashMode: int;
    var reclaimId: int;
    var reclaimCrash: bool;
    var dual: bool;
    var i: int;
    var cm: int;
    var done: (acked: bool, id: int, hash: int);

    start state Init {
        entry (input: tDiskScenarioConfig) {
            parent = input.parent;
            nSegments = input.nSegments;
            crashMode = input.crashMode;
            reclaimId = input.reclaimId;
            reclaimCrash = input.reclaimCrash;
            dual = input.dual;
            store = new DiskStore();
            log = new MutationLog();

            if (dual) {
                new DiskWriter((parent=this, store=store, log=log, id=0, hash=100, crashMode=0, offs=emptyKeys()));
                new DiskWriter((parent=this, store=store, log=log, id=0, hash=200, crashMode=0, offs=emptyKeys()));
                i = 0;
                while (i < 2) {
                    receive {
                        case eWriterDone: (payload: (acked: bool, id: int, hash: int)) {}
                    }
                    i = i + 1;
                }
                new DiskRecover((parent=this, store=store, log=log, maxId=1));
                waitRecover();
            } else {
                i = 0;
                while (i < nSegments) {
                    cm = 0;
                    if (i == 0) {
                        if (crashMode == 1) {
                            cm = 1;
                        } else {
                            if (crashMode == 2) {
                                cm = 4;
                            } else {
                                if (crashMode == 3) {
                                    cm = 2;
                                }
                            }
                        }
                    }
                    new DiskWriter((parent=this, store=store, log=log, id=i, hash=10 + i, crashMode=cm, offs=emptyKeys()));
                    receive {
                        case eWriterDone: (payload: (acked: bool, id: int, hash: int)) {
                            done = payload;
                        }
                    }
                    i = i + 1;
                }
                new DiskRecover((parent=this, store=store, log=log, maxId=nSegments));
                waitRecover();
                if (reclaimId >= 0) {
                    new DiskApplyGc((parent=this, store=store, log=log, id=reclaimId, crashAfterCommitDelete=reclaimCrash));
                    receive {
                        case eApplyGcDone: (payload: (id: int, crashed: bool)) {}
                    }
                    new DiskRecover((parent=this, store=store, log=log, maxId=nSegments));
                    waitRecover();
                }
            }

            send parent, eScenarioDone;
        }
    }
}

machine SingleWriterNoCrash {
    start state Init {
        entry {
            new DiskScenario((parent=this, nSegments=2, crashMode=0, reclaimId=-1, reclaimCrash=false, dual=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine CrashAfterBodyBeforeCommit {
    start state Init {
        entry {
            new DiskScenario((parent=this, nSegments=2, crashMode=1, reclaimId=-1, reclaimCrash=false, dual=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine CrashAfterPreparedBeforeCommitted {
    start state Init {
        entry {
            new DiskScenario((parent=this, nSegments=1, crashMode=3, reclaimId=-1, reclaimCrash=false, dual=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine CrashAfterCommitBeforeAck {
    start state Init {
        entry {
            new DiskScenario((parent=this, nSegments=1, crashMode=2, reclaimId=-1, reclaimCrash=false, dual=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine CrashAfterCommitDeleteBeforeBody {
    start state Init {
        entry {
            new DiskScenario((parent=this, nSegments=1, crashMode=0, reclaimId=0, reclaimCrash=true, dual=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine GcHole {
    start state Init {
        entry {
            new DiskScenario((parent=this, nSegments=3, crashMode=0, reclaimId=1, reclaimCrash=false, dual=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine DualWriter {
    start state Init {
        entry {
            new DiskScenario((parent=this, nSegments=1, crashMode=0, reclaimId=-1, reclaimCrash=false, dual=true));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine FlushAtomicTwoKeys {
    var store: DiskStore;
    var log: MutationLog;
    var core: DiskIngestCore;

    start state Init {
        entry {
            store = new DiskStore();
            log = new MutationLog();
            core = new DiskIngestCore((parent=this, store=store, log=log));
            send core, eIngestSubmit, (key=0,);
            send core, eIngestSubmit, (key=1,);
            send core, eIngestFlush, (crashMode=0, hash=100, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
            send core, eIngestSubmit, (key=0,);
            send core, eIngestSubmit, (key=1,);
            send core, eIngestFlush, (crashMode=0, hash=101, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
        }
    }
}

machine SourceRetryAfterPanic {
    var store: DiskStore;
    var log: MutationLog;
    var core: DiskIngestCore;

    start state Init {
        entry {
            store = new DiskStore();
            log = new MutationLog();
            core = new DiskIngestCore((parent=this, store=store, log=log));
            send core, eIngestSubmit, (key=0,);
            send core, eIngestFlush, (crashMode=4, hash=100, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
            send core, eIngestSubmit, (key=0,);
            send core, eIngestFlush, (crashMode=0, hash=101, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
        }
    }
}

machine TimeoutReconcileCloses {
    var store: DiskStore;
    var log: MutationLog;
    var core: DiskIngestCore;

    start state Init {
        entry {
            store = new DiskStore();
            log = new MutationLog();
            core = new DiskIngestCore((parent=this, store=store, log=log));
            send core, eIngestSubmit, (key=0,);
            send core, eIngestFlush, (crashMode=0, hash=100, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
            send core, eIngestSubmit, (key=0,);
            send core, eIngestFlush, (crashMode=0, hash=101, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
        }
    }
}

machine CommitNeverLandedSourceRetry {
    var store: DiskStore;
    var log: MutationLog;
    var core: DiskIngestCore;

    start state Init {
        entry {
            store = new DiskStore();
            log = new MutationLog();
            core = new DiskIngestCore((parent=this, store=store, log=log));
            send core, eIngestSubmit, (key=0,);
            send core, eIngestFlush, (crashMode=2, hash=100, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
            send core, eIngestSubmit, (key=0,);
            send core, eIngestFlush, (crashMode=0, hash=101, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
        }
    }
}

machine TwoFlushesTwoUnits {
    var store: DiskStore;
    var log: MutationLog;
    var core: DiskIngestCore;

    start state Init {
        entry {
            store = new DiskStore();
            log = new MutationLog();
            core = new DiskIngestCore((parent=this, store=store, log=log));
            send core, eIngestSubmit, (key=0,);
            send core, eIngestFlush, (crashMode=0, hash=10, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
            send core, eIngestSubmit, (key=1,);
            send core, eIngestFlush, (crashMode=2, hash=11, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
            send core, eIngestSubmit, (key=0,);
            send core, eIngestSubmit, (key=1,);
            send core, eIngestFlush, (crashMode=0, hash=12, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
        }
    }
}

machine RestoreLiveNewId {
    var store: DiskStore;
    var log: MutationLog;
    var core: DiskIngestCore;

    start state Init {
        entry {
            store = new DiskStore();
            log = new MutationLog();
            core = new DiskIngestCore((parent=this, store=store, log=log));
            send core, eIngestSubmit, (key=0,);
            send core, eIngestFlush, (crashMode=4, hash=100, restoreBad=true);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
        }
    }
}


