// Disk-backed key/value store. Writes land in a pending buffer and become
// visible to GET/LIST only after an explicit Sync (fdatasync + dir fsync).

event eDiskWriteRequest: (sender: machine, key: string, value: data);
event eDiskWriteResponse: (success: bool);

event eDiskSyncRequest: (sender: machine);
event eDiskSyncResponse: (success: bool);

event eDiskReadRequest: (sender: machine, key: string);
event eDiskReadResponse: (success: bool, value: data);

event eDiskDeleteRequest: (sender: machine, key: string);
event eDiskDeleteResponse: (success: bool);

event eDiskListRequest: (sender: machine, prefix: string);
event eDiskListResponse: (keyList: seq[string]);

machine DiskStore {
    var objects: map[string, data];
    var pending: map[string, data];

    start state Init {
        entry {}

        on eDiskWriteRequest do (payload: (sender: machine, key: string, value: data)) {
            pending[payload.key] = payload.value;
            send payload.sender, eDiskWriteResponse, (success=true,);
        }

        on eDiskSyncRequest do (payload: (sender: machine)) {
            var pendingKeys: seq[string];
            var i: int;
            var k: string;

            pendingKeys = keys(pending);
            i = 0;
            while (i < sizeof(pendingKeys)) {
                k = pendingKeys[i];
                objects[k] = pending[k];
                i = i + 1;
            }
            pending = default(map[string, data]);
            send payload.sender, eDiskSyncResponse, (success=true,);
        }

        on eDiskReadRequest do (payload: (sender: machine, key: string)) {
            if (payload.key in objects) {
                send payload.sender, eDiskReadResponse, (success=true, value=objects[payload.key]);
            } else {
                send payload.sender, eDiskReadResponse, (success=false, value=null);
            }
        }

        on eDiskDeleteRequest do (payload: (sender: machine, key: string)) {
            if (payload.key in objects) {
                objects -= (payload.key);
            }
            if (payload.key in pending) {
                pending -= (payload.key);
            }
            send payload.sender, eDiskDeleteResponse, (success=true,);
        }

        on eDiskListRequest do (payload: (sender: machine, prefix: string)) {
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
            send payload.sender, eDiskListResponse, (keyList=out,);
        }
    }
}
