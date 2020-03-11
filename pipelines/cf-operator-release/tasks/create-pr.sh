#!/bin/bash

set -e

url=$( cat s3.release.helm-charts/url )
version=$( cat s3.release.helm-charts/version )
sha=$( cat s3.shas/$version )
version=$(echo "$version" | sed 's/+/%2B/')

pushd kubecf-src/
sed -i '/\"cf_operator\": struct/{n;n;s,".*","'$sha'",}' ./def.bzl
sed -i '/\"cf_operator\": struct/{n;n;n;s,".*","'$version'",}' ./def.bzl
git checkout -b bot/cf-operator

git config --global user.name "CFContainerizationBot"
git config --global user.email "cfcontainerizationbot@cloudfoundry.org"
git add .
git commit -m "feat: bump cf-operator $url $version"
git config --global credential.helper cache
git config core.sshCommand 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
git config --global core.editor "cat"

git push https://$USERNAME:$PASSWORD@github.com/cloudfoundry-incubator/kubecf.git bot/cf-operator
git pull-request --no-fork --title "Update cf-operator dependency." --message "Increment cf-operator version in def.bzl file."
popd
