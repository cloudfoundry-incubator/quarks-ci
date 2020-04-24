#!/bin/bash

set -e

url=$( cat s3.release.helm-charts/url )
version=$( cat s3.release.helm-charts/version )
sha=$( cat s3.shas/$version )
version=$(echo "$version" | sed 's/+/%2B/')

export GIT_ASKPASS=../ci/pipelines/cf-operator-release/tasks/git-password.sh

pushd kubecf-src/
sed -i "/cf_operator:/{n;s/sha256: \(.*\)/sha256: ${sha}/}" ./dependencies.yaml
sed -i "/cf_operator:/{n;n;n;s/version: \(.*\)/version: ${version}/}" ./dependencies.yaml
git checkout -b bot/cf-operator

git config --global user.name "CFContainerizationBot"
git config --global user.email "cf-containerization@cloudfoundry.org"
git config credential.https://github.com.username CFContainerizationBot
git add .
git commit -m "feat: bump cf-operator $url $version"
git config --global credential.helper cache
git config core.sshCommand 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
git config --global core.editor "cat"

git push -f origin bot/cf-operator
git pull-request --no-fork --title "Update cf-operator dependency." --message "Increment cf-operator version in def.bzl file."
popd
