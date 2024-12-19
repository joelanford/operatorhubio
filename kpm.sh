#!/usr/bin/env bash

set -euo pipefail

: "${CATALOG_DIR:?Need to set CATALOG_DIR}"
: "${OPERATORS_DIR:?Need to set OPERATORS_DIR}"
: "${REPO:?Need to set REPO}"
: "${CATALOG_TAG:?Need to set CATALOG_TAG}"
: "${KPM_PACKAGES:?Need to set KPM_PACKAGES. Use 'KPM_PACKAGES=ALL' to rebuild the entire catalog}"

mkdir -p ${CATALOG_DIR}
catalogDir=$(cd "${CATALOG_DIR}" && pwd)
operatorsDir=$(cd "${OPERATORS_DIR}" && pwd)
repo="${REPO}"
catalogTag="${CATALOG_TAG}"

kpmSpecDir="kpmspecs"
kpmDir="kpms"

if [[ "$KPM_PACKAGES" == "CHANGED" ]] then
	: "${SINCE_COMMIT:?Need to set SINCE_COMMIT}"
	sinceCommit="${SINCE_COMMIT}"
	packages=$(cd $operatorsDir && git diff --name-only $sinceCommit | grep '^operators/' | cut -d'/' -f2 | sort | uniq)
elif [[ "$KPM_PACKAGES" == "ALL" ]]; then
	packages=$(find $operatorsDir -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort)
else
	packages=${KPM_PACKAGES}
fi

for p in $packages; do
	mkdir -p $kpmSpecDir && rm -rf $kpmSpecDir/$p*
	mkdir -p $kpmDir     && rm -rf $kpmDir/$p*
	mkdir -p $catalogDir && rm -rf $catalogDir/$p*

	specFile="$kpmSpecDir/$p.catalog.kpmspec.yaml"
	echo "creating $specFile"
	cat << EOF > $specFile
apiVersion: specs.kpm.io/v1
kind: Catalog

imageReference: $repo:$p-catalog-$catalogTag
cacheFormat: none
source:
  sourceType: legacy
  legacy:
    bundleRoot: $operatorsDir/$p
    bundleImageReference: $repo:$p-bundle-{.Version}

EOF
	kpm build catalog $specFile -o $kpmDir

	kpmFile=$(ls $kpmDir/$(basename "$repo")-$p-catalog-$catalogTag.catalog.kpm)

	mkdir $catalogDir/$p
	kpm render $kpmFile > $catalogDir/$p/catalog.json
done

cat << EOF > $kpmSpecDir/catalog.kpmspec.yaml
apiVersion: specs.kpm.io/v1
kind: Catalog

imageReference: $repo:$catalogTag

cacheFormat: pogreb.v1
migrationLevel: all

source:
  sourceType: fbc
  fbc:
    catalogRoot: $catalogDir
EOF
kpm build catalog $kpmSpecDir/catalog.kpmspec.yaml -o $kpmDir
