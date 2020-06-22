#!/bin/bash

set -ev

url=$( cat s3.release.helm-charts/url )
version=$( cat s3.release.helm-charts/version )

helm repo index --merge helm-repo/index.yaml s3.release.helm-charts

cp -av helm-repo/. updated/
cp -pv s3.release.helm-charts/*tgz updated/
cp -pv s3.release.helm-charts/index.yaml updated/

pushd updated
  git add .
  git config --global user.name "CFContainerizationBot"
  git config --global user.email "cf-containerization@cloudfoundry.org"
  git commit -m "add helm chart for $url $version"
popd
