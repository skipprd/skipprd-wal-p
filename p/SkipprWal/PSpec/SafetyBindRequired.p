/// Safety: an admitted pair must bind (body hash == commit hash).
spec SafetyBindRequired observes eRecoverAdmit {
    start state Observing {
        entry {}

        on eRecoverAdmit do (payload: (id: int, bodyHash: int, commitHash: int)) {
            assert payload.bodyHash == payload.commitHash,
                format("admitted unbound pair {0}: body {1} commit {2}",
                    payload.id, payload.bodyHash, payload.commitHash);
        }
    }
}
