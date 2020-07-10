#!/bin/bash

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -ex

[ -f release/tag ] || ( echo "failed to determine tag. create a draft release first"; exit 1 )


# The version authority is on git.
# Until we get version from a concourse resource, we need to make sure
# assets versions match the Github tag.
echo "check assets versions"
semver=$( sed 's/^v//; s/-/+/' release/tag )
if ! grep -q "$semver" s3.helm-charts/version; then
  echo -n "Helm chart version does not match Github tag from Github release: "
  grep . s3.helm-charts/version release/tag
  exit 1
fi

# Binary version is like docker version, using dash instead of plus
if ! grep -qf release/tag s3.cf-operator/version; then
  echo -n "Operator binary version does not match Github tag from Github release: "
  cat s3.cf-operator/version
  exit 1
fi

# Docker versions are not strictly following the semantic versioning spc
docker_tag=$(tar xOfz s3.helm-charts/cf-operator-*.tgz cf-operator/values.yaml | grep "  tag: v")
if ! echo "$docker_tag" | grep -qf release/tag; then
  echo -n "Helm chart does not reference a docker image with the right Github"
  echo "$docker_tag"
  exit 1
fi

# start editing the draft release on Github
echo "zip cfo binary"
cp s3.cf-operator/cf-operator-* out
gzip out/cf-operator-*

echo "updating release text"
cat release/tag > out/name
cp release/tag out/
touch release/body
cp release/body out/

binary_version=$(cat s3.cf-operator/version)

version=$(column -t s3.helm-charts/version | python -c "import urllib, sys; print urllib.quote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1], \"\")")
helm_chart_url="release/helm-charts/cf-operator-$version.tgz"

cat >> out/body <<EOF

# New Features

...

# Known Issues

...

# Installation

    # Use this if you've never installed the operator before
    helm repo add quarks https://cloudfoundry-incubator.github.io/quarks-helm/
    helm install cf-operator quarks/cf-operator

    # Use this if the custom resources have already been created by a previous CF Operator installation
    helm repo update
    helm install cf-operator quarks/cf-operator --set "customResources.enableInstallation=false"

    # For more options look at the README for the chart
    helm show readme quarks/cf-operator

# Assets

Helm repository

* https://cloudfoundry-incubator.github.io/quarks-helm/

Helm chart and standalone binary:

* https://s3.amazonaws.com/cf-operators/$helm_chart_url
* https://s3.amazonaws.com/cf-operators/release/binaries/cf-operator-$binary_version

EOF
