# OperatorHub

This repository consists of a single GitHub workflow and a single script that builds an alternate version of the OperatorHub.io catalog.

The alternate catalog is available at [`ghcr.io/joelanford/operatorhubio:latest`](https://github.com/joelanford/operatorhubio/pkgs/container/operatorhubio)

## Whatever! How do I use it?
To use it with OLMv1, run the following command:
```sh
kubectl apply -f - << EOF
apiVersion: olm.operatorframework.io/v1
kind: ClusterCatalog
metadata:
  name: joes-operatorhubio
spec:
  source:
    type: Image
    image:
      ref: ghcr.io/joelanford/operatorhubio:latest
      pollIntervalMinutes: 60
EOF
```
