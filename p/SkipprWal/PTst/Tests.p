type tScenarioConfig = (
    parent: machine,
    nSegments: int,
    crashMode: int,
    reclaimId: int,
    reclaimCrash: bool,
    dual: bool,
    lossy: bool,
    retryNewId: bool
);

machine Scenario {
    var parent: machine;
    var store: ObjectStore;
    var nSegments: int;
    var crashMode: int;
    var reclaimId: int;
    var reclaimCrash: bool;
    var dual: bool;
    var lossy: bool;
    var retryNewId: bool;
    var i: int;
    var cm: int;
    var done: (acked: bool, id: int, hash: int);

    start state Init {
        entry (input: tScenarioConfig) {
            parent = input.parent;
            nSegments = input.nSegments;
            crashMode = input.crashMode;
            reclaimId = input.reclaimId;
            reclaimCrash = input.reclaimCrash;
            dual = input.dual;
            lossy = input.lossy;
            retryNewId = input.retryNewId;
            store = new ObjectStore(lossy);

            if (retryNewId) {
                new Writer((parent=this, store=store, id=0, hash=100, crashMode=2, offs=emptyKeys()));
                receive {
                    case eWriterDone: (payload: (acked: bool, id: int, hash: int)) {}
                }
                new Writer((parent=this, store=store, id=1, hash=100, crashMode=0, offs=emptyKeys()));
                receive {
                    case eWriterDone: (payload: (acked: bool, id: int, hash: int)) {}
                }
                new Recover((parent=this, store=store, maxId=2));
                waitRecover();
            } else {
                if (dual) {
                    new Writer((parent=this, store=store, id=0, hash=100, crashMode=0, offs=emptyKeys()));
                    new Writer((parent=this, store=store, id=0, hash=200, crashMode=0, offs=emptyKeys()));
                    i = 0;
                    while (i < 2) {
                        receive {
                            case eWriterDone: (payload: (acked: bool, id: int, hash: int)) {}
                        }
                        i = i + 1;
                    }
                    new Recover((parent=this, store=store, maxId=1));
                    waitRecover();
                } else {
                    i = 0;
                    while (i < nSegments) {
                        cm = 0;
                        if (i == 0) {
                            cm = crashMode;
                        }
                        new Writer((parent=this, store=store, id=i, hash=10 + i, crashMode=cm, offs=emptyKeys()));
                        receive {
                            case eWriterDone: (payload: (acked: bool, id: int, hash: int)) {
                                done = payload;
                            }
                        }
                        i = i + 1;
                    }
                    new Recover((parent=this, store=store, maxId=nSegments));
                    waitRecover();
                    if (reclaimId >= 0) {
                        new ApplyGc((parent=this, store=store, id=reclaimId, crashAfterCommitDelete=reclaimCrash));
                        receive {
                            case eApplyGcDone: (payload: (id: int, crashed: bool)) {}
                        }
                        new Recover((parent=this, store=store, maxId=nSegments));
                        waitRecover();
                    }
                }
            }

            send parent, eScenarioDone;
        }
    }
}

machine SingleWriterNoCrash {
    start state Init {
        entry {
            new Scenario((parent=this, nSegments=2, crashMode=0, reclaimId=-1, reclaimCrash=false, dual=false, lossy=false, retryNewId=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine CrashAfterBodyBeforeCommit {
    start state Init {
        entry {
            new Scenario((parent=this, nSegments=2, crashMode=1, reclaimId=-1, reclaimCrash=false, dual=false, lossy=false, retryNewId=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine CrashAfterCommitBeforeAck {
    start state Init {
        entry {
            new Scenario((parent=this, nSegments=1, crashMode=2, reclaimId=-1, reclaimCrash=false, dual=false, lossy=false, retryNewId=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine CrashAfterCommitDeleteBeforeBody {
    start state Init {
        entry {
            new Scenario((parent=this, nSegments=1, crashMode=0, reclaimId=0, reclaimCrash=true, dual=false, lossy=false, retryNewId=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine GcHole {
    start state Init {
        entry {
            new Scenario((parent=this, nSegments=3, crashMode=0, reclaimId=1, reclaimCrash=false, dual=false, lossy=false, retryNewId=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine DualWriter {
    start state Init {
        entry {
            new Scenario((parent=this, nSegments=1, crashMode=0, reclaimId=-1, reclaimCrash=false, dual=true, lossy=false, retryNewId=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine TimeoutReconcileAck {
    start state Init {
        entry {
            new Scenario((parent=this, nSegments=1, crashMode=3, reclaimId=-1, reclaimCrash=false, dual=false, lossy=false, retryNewId=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine TimeoutCommitNeverLanded {
    start state Init {
        entry {
            new Scenario((parent=this, nSegments=1, crashMode=4, reclaimId=-1, reclaimCrash=false, dual=false, lossy=false, retryNewId=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine TimeoutGetUnknownPanic {
    start state Init {
        entry {
            new Scenario((parent=this, nSegments=1, crashMode=5, reclaimId=-1, reclaimCrash=false, dual=false, lossy=false, retryNewId=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine TimeoutLossyPuts {
    start state Init {
        entry {
            new Scenario((parent=this, nSegments=1, crashMode=0, reclaimId=-1, reclaimCrash=false, dual=false, lossy=true, retryNewId=false));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine RetryNewId {
    start state Init {
        entry {
            new Scenario((parent=this, nSegments=1, crashMode=0, reclaimId=-1, reclaimCrash=false, dual=false, lossy=false, retryNewId=true));
            receive {
                case eScenarioDone: {}
            }
        }
    }
}

machine FlushAtomicTwoKeys {
    var store: ObjectStore;
    var core: IngestCore;

    start state Init {
        entry {
            store = new ObjectStore(false);
            core = new IngestCore((parent=this, store=store));
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
    var store: ObjectStore;
    var core: IngestCore;

    start state Init {
        entry {
            store = new ObjectStore(false);
            core = new IngestCore((parent=this, store=store));
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

machine TimeoutReconcileCloses {
    var store: ObjectStore;
    var core: IngestCore;

    start state Init {
        entry {
            store = new ObjectStore(false);
            core = new IngestCore((parent=this, store=store));
            send core, eIngestSubmit, (key=0,);
            send core, eIngestFlush, (crashMode=3, hash=100, restoreBad=false);
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
    var store: ObjectStore;
    var core: IngestCore;

    start state Init {
        entry {
            store = new ObjectStore(false);
            core = new IngestCore((parent=this, store=store));
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

machine TwoFlushesTwoUnits {
    var store: ObjectStore;
    var core: IngestCore;

    start state Init {
        entry {
            store = new ObjectStore(false);
            core = new IngestCore((parent=this, store=store));
            send core, eIngestSubmit, (key=0,);
            send core, eIngestFlush, (crashMode=0, hash=10, restoreBad=false);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
            send core, eIngestSubmit, (key=1,);
            send core, eIngestFlush, (crashMode=4, hash=11, restoreBad=false);
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
    var store: ObjectStore;
    var core: IngestCore;

    start state Init {
        entry {
            store = new ObjectStore(false);
            core = new IngestCore((parent=this, store=store));
            send core, eIngestSubmit, (key=0,);
            send core, eIngestFlush, (crashMode=2, hash=100, restoreBad=true);
            receive {
                case eIngestCoreDone: (payload: (acked: bool, id: int, hash: int)) {}
            }
        }
    }
}


