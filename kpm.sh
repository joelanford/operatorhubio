#!/usr/bin/env bash

registryNamespace="quay.io/operatorhubio-jwl"

kpmSpecDir="kpmspecs"
kpmDir="kpms"
catalogDir="catalog"
catalogTag=$(git branch --show-current)
if [[ $catalogTag == "main" ]]; then
	catalogTag="latest"
fi

if [[ "$KPM_PACKAGES" == "" ]]; then
	echo "KPM_PACKAGES must be set. Use 'KPM_PACKAGES=ALL' to rebuild the entire repo."
	exit 1
elif [[ "$KPM_PACKAGES" == "CHANGED" ]] then
	packages=$(git diff --name-only HEAD~  | grep '^operators/' | cut -d'/' -f2 | sort | uniq)
elif [[ "$KPM_PACKAGES" == "ALL" ]]; then
        rm -rf $kpmSpecDir
        rm -rf $kpmDir
        rm -rf $catalogDir
	packages=$(find operators -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort)
else
	packages=${KPM_PACKAGE}
fi

count=0
for p in $packages; do
	mkdir -p $kpmSpecDir && rm -rf $kpmSpecDir/$p*
	mkdir -p $kpmDir     && rm -rf $kpmDir/$p*
	mkdir -p $catalogDir && rm -rf $catalogDir/$p*

	specFile="$kpmSpecDir/$p.catalog.kpmspec.yaml"
	echo "creating $specFile"
	cat << EOF > $specFile
apiVersion: specs.kpm.io/v1
kind: Catalog

registryNamespace: $registryNamespace
name: $p-catalog
tag: $catalogTag

cacheFormat: none

source:
  sourceType: legacy
  legacy:
    bundleRoot: ../operators/$p
    bundleRegistryNamespace: $registryNamespace

EOF
	kpm build catalog $specFile -o $kpmDir
	
	kpmFile=$(ls $kpmDir/$p-catalog-$catalogTag.catalog.kpm)

	mkdir $catalogDir/$p
	kpm render $kpmFile > $catalogDir/$p/catalog.json

	((count=count+1))
done

cat << EOF > $kpmSpecDir/operatorhubio.catalog.kpmspec.yaml
apiVersion: specs.kpm.io/v1
kind: Catalog

registryNamespace: $registryNamespace
name: catalog
tag: $catalogTag

cacheFormat: pogreb.v1
migrationLevel: all

source:
  sourceType: fbc
  fbc:
    catalogRoot: ../catalog
EOF
kpm build catalog $kpmSpecDir/operatorhubio.catalog.kpmspec.yaml -o $kpmDir
