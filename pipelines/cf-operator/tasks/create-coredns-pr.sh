#!/bin/bash

set -e

: "${coredns_repo:?}"

# find new coredns version
pushd docker.coredns
version=$(cat digest)
url="$coredns_repo@$version"
rpmversion=$(chroot rootfs rpm -q coredns)
popd

# create pr for quarks-operator
export GIT_ASKPASS="$PWD/ci/pipelines/cf-operator-release/tasks/git-password.sh"
git config --global user.name "CFContainerizationBot"
git config --global user.email "cf-containerization@cloudfoundry.org"

pushd src
# setup git
git config credential.https://github.com.username CFContainerizationBot

# make commit
git checkout -b bot/bump-coredns
sed -i "s#boshDNSDockerImage: \".*#boshDNSDockerImage: \"$url\"#" deploy/helm/cf-operator/values.yaml
git --no-pager diff

# create pr
git commit -a -m "Bump coredns to $rpmversion"
git config --global credential.helper cache
git config core.sshCommand 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
git config --global core.editor "cat"
git push -f origin bot/bump-coredns
git pull-request --no-fork --title "Update coredns dependency." --message "Bump the coredns in the helm chart to $rpmversion"
popd
