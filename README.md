# OperatorHub


<a href="https://github.com/joelanford/operatorhubio/actions/workflows/release.yaml?query=event%3Aschedule+branch%3Amain">
  <img src="https://github.com/joelanford/operatorhubio/actions/workflows/release.yaml/badge.svg?branch=main&event=schedule" alt="release.yaml workflow status"/>
</a>

This repository consists of a single GitHub workflow and a single script that builds an alternate version of the OperatorHub.io catalog.

## Install

### OLMv1

To install the catalog built from this repo for OLMv1, run the following in a terminal:
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

### OLMv0

To install the catalog built from this repo for OLMv0, run the following in a terminal:
```sh
kubectl apply -f - << EOF
apiVersion: "operators.coreos.com/v1alpha1"
kind: "CatalogSource"
metadata:
  name: "joes-operatorhubio-catalog"
  namespace: "olm"
spec:
  sourceType: grpc
  image: ghcr.io/joelanford/operatorhubio:latest
  displayName: "Community Operators (Joe's mirror)"
  publisher: "joelanford"
  updateStrategy:
    registryPoll:
      interval: 60m
  grpcPodConfig:
    securityContextConfig: restricted
    extractContent:
      cacheDir: /tmp/cache
      catalogDir: /configs
EOF
```

## How does it work?

The workflow runs automatically every hour, (re-)building bundles, (re-)building package-specific catalogs, and (re-)building the main operatorhub catalog.

The underlying technology is my experimental [`kpm`](https://github.com/joelanford/kpm) tool, which eschews typical container build tools and focuses on the minimal OCI-compliant necessities to build reproducible (same content -> same digest) bundles and catalogs much faster and with no other runtime dependencies. You can directly build and push bundles and catalogs on macOS, no Linux VM necessary!

## Wait, did you say "package-specific catalogs"?

Yes, I did! In addition to a rebuild of the main operatorhub.io catalog, the repo _also_ builds and pushes a catalog image for each individual package.

To use a package-specific catalog simply use the package-specific tag (`<packageName>-catalog-<latest>`).

For example,
```
ghcr.io/joelanford/operatorhubio:cert-manager-catalog-latest
```

