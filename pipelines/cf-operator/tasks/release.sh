#!/bin/bash
set -e

[ -f release/tag ] || ( echo "failed to determine tag. create a draft release first"; exit 1 )

echo "zip cfo binary"
cp s3.cf-operator/cf-operator-* out
gzip out/cf-operator-*

echo "updating release text"
cat release/tag > out/name
cp release/tag out/
cp -f release/body out/

binary_version=$(cat s3.cf-operator/version)

version=$(python -c "import urllib, sys; print urllib.quote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1], \"\")" < s3.helm-charts/version)
helm_chart="release/helm-charts/cf-operator-$version.tgz"

cat >> out/body <<EOF

# New Features

...

# Known Issues

...

# Installation

    # Use this if you've never installed the operator before
    helm install --namespace cf-operator --name cf-operator https://s3.amazonaws.com/cf-operators/release/helm-charts/$helm_chart

    # Use this if the custom resources have already been created by a previous CF Operator installation
    helm install --namespace cf-operator --name cf-operator https://s3.amazonaws.com/cf-operators/release/helm-charts/$helm_chart --set "customResources.enableInstallation=false"

# Assets

Helm chart and standalone binary:

* https://s3.amazonaws.com/cf-operators/$helm_chart
* https://s3.amazonaws.com/cf-operators/release/binaries/cf-operator-$binary_version

EOF
