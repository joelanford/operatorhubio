# OperatorHub

![example workflow](https://github.com/joelanford/operatorhubio/actions/workflows/release.yaml/badge.svg)

This repository consists of a single GitHub workflow and a single script that builds an alternate version of the OperatorHub.io catalog.

## Install

To install the catalog built from this repo, run the following in a terminal:
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

## How does it work?

The workflow runs automatically every hour, (re-)building bundles, (re-)building package-specific catalogs, and (re-)building the main operatorhub catalog.

The underlying technology is my experimental [`kpm`](https://github.com/joelanford/kpm) tool, which eschews typical container build tools and focuses on the minimal OCI-compliant necessities to build reproducible (same content -> same digest) bundles and catalogs much faster and with no other runtime dependencies. You can directly build and push bundles and catalogs on a macOS, no Linux VM necessary!

## Wait, did you say "package-specific catalogs"?

Yes, I did! In addition to a rebuild of the main operatorhub.io catalog, the repo _also_ builds and pushes a catalog image for each individual package.

To use a package-specific catalog simply use the package-specific tag (`<packageName>-catalog-<latest>`).

For example,
```
ghcr.io/joelanford/operatorhubio:cert-manager-catalog-latest
```

