#!/bin/bash

set -ev

url=$( cat s3.release.helm-charts/url )
version=$( cat s3.release.helm-charts/version )

cp -rv helm-repo/. updated/
cp -v s3.release.helm-charts/*tgz updated/

pushd updated
  helm3 repo index .
  git add .
  git config --global user.name "CFContainerizationBot"
  git config --global user.email "cfcontainerizationbot@cloudfoundry.org"
  git commit -m "add helm chart for $url $version"
popd
