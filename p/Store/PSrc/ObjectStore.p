// Object store with per-key PUT/GET/DELETE, optional CAS, and List.
// Adapted from OSWALD's ObjectStore (MIT): one machine so two PUTs
// interleave with Recover — that *is* the body-without-commit window.
//
// expected_version:
//   -1  unconditional PUT (S3 WAL writer)
//    0  create if not exists (If-None-Match: *)
//   >0  PUT only if current version matches (If-Match)
//
// lossy: when true, unconditional PUTs may return unknown. The write
// may already be applied (lost 200) or dropped (never landed). The
// writer must not treat unknown as "mint a new id."

type tUploadRequest = (sender: machine, key: string, value: data, expected_version: int);
type tUploadResponse = (success: bool, unknown: bool, applied: bool, current_version: int);

event eUploadRequest: tUploadRequest;
event eUploadResponse: tUploadResponse;

type tDownloadRequest = (sender: machine, key: string);
type tDownloadResponse = (success: bool, unknown: bool, value: data, version: int);

event eDownloadRequest: tDownloadRequest;
event eDownloadResponse: tDownloadResponse;

type tDeleteRequest = (sender: machine, key: string);
type tDeleteResponse = (success: bool);

event eDeleteRequest: tDeleteRequest;
event eDeleteResponse: tDeleteResponse;

type tListRequest = (sender: machine, prefix: string);
type tListResponse = (keyList: seq[string]);

event eListRequest: tListRequest;
event eListResponse: tListResponse;

event eObjectUpdated: (key: string, value: data, version: int);

type Value = (body: data, version: int);

machine ObjectStore {
    var objects: map[string, Value];
    var lossy: bool;

    start state Init {
        entry (lossyPuts: bool) {
            lossy = lossyPuts;
        }

        on eUploadRequest do (payload: tUploadRequest) {
            var current_value: Value;
            var choice: int;
            var doApply: bool;
            var unknown: bool;
            var ver: int;

            doApply = true;
            unknown = false;

            if (lossy && payload.expected_version == -1) {
                choice = choose(3);
                if (choice == 1) {
                    unknown = true;
                } else {
                    if (choice == 2) {
                        unknown = true;
                        doApply = false;
                    }
                }
            }

            if (doApply) {
                if (payload.key in objects) {
                    current_value = objects[payload.key];

                    if (payload.expected_version == -1 || current_value.version == payload.expected_version) {
                        objects[payload.key] = (body=payload.value, version=current_value.version + 1);
                        ver = objects[payload.key].version;
                        announce eObjectUpdated, (key=payload.key, value=payload.value, version=ver);
                        if (unknown) {
                            send payload.sender, eUploadResponse, (success=false, unknown=true, applied=true, current_version=ver);
                        } else {
                            send payload.sender, eUploadResponse, (success=true, unknown=false, applied=true, current_version=ver);
                        }
                    } else {
                        send payload.sender, eUploadResponse, (success=false, unknown=false, applied=false, current_version=current_value.version);
                    }
                } else {
                    if (payload.expected_version == 0 || payload.expected_version == -1) {
                        objects[payload.key] = (body=payload.value, version=1);
                        announce eObjectUpdated, (key=payload.key, value=payload.value, version=1);
                        if (unknown) {
                            send payload.sender, eUploadResponse, (success=false, unknown=true, applied=true, current_version=1);
                        } else {
                            send payload.sender, eUploadResponse, (success=true, unknown=false, applied=true, current_version=1);
                        }
                    } else {
                        send payload.sender, eUploadResponse, (success=false, unknown=false, applied=false, current_version=0);
                    }
                }
            } else {
                send payload.sender, eUploadResponse, (success=false, unknown=true, applied=false, current_version=0);
            }
        }

        on eDownloadRequest do (payload: tDownloadRequest) {
            var value: Value;

            if (payload.key in objects) {
                value = objects[payload.key];
                send payload.sender, eDownloadResponse, (success=true, unknown=false, value=value.body, version=value.version);
            } else {
                send payload.sender, eDownloadResponse, (success=false, unknown=false, value=null, version=0);
            }
        }

        on eDeleteRequest do (payload: tDeleteRequest) {
            if (payload.key in objects) {
                objects -= (payload.key);
            }
            announce eObjectUpdated, (key=payload.key, value=null, version=0);
            send payload.sender, eDeleteResponse, (success=true,);
        }

        on eListRequest do (payload: tListRequest) {
            var all: seq[string];
            var out: seq[string];
            var i: int;
            var k: string;

            all = keys(objects);
            i = 0;
            while (i < sizeof(all)) {
                k = all[i];
                if (payload.prefix == "") {
                    out += (sizeof(out), k);
                } else {
                    if (k == payload.prefix) {
                        out += (sizeof(out), k);
                    }
                }
                i = i + 1;
            }
            send payload.sender, eListResponse, (keyList=out,);
        }
    }
}
