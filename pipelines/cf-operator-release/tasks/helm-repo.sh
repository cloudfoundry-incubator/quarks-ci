#!/bin/bash

set -ev

url=$( cat s3.release.helm-charts/url )
version=$( cat s3.release.helm-charts/version )

cp -av helm-repo/. updated/
cp -pv s3.release.helm-charts/*tgz updated/

pushd updated
  helm repo index .
  git add .
  git config --global user.name "CFContainerizationBot"
  git config --global user.email "cf-containerization@cloudfoundry.org"
  git commit -m "add helm chart for $url $version"
popd
