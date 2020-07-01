#!/usr/bin/env sh

set -ex

echo "==== obs image"
grep . lftp.obs-docker-stemcell/*
echo


echo "==== current git tag"
cd src
old=$(git describe --tags "$(git rev-list --tags --max-count=1)")
echo "Found previous tag: $old"
ruby -e 'a=ARGV[0].split(/\./); a[-1]=a[-1].to_i+1; print a.join(".")' "$old" > ../tag/name
echo "Bump version for image update from OBS" > ../tag/message
echo "Output:"
grep . ../tag/*
echo

cp -a . ../modified
cd ../modified

echo "==== create empty commit to trigger concourse"
git config --global user.name "CFContainerizationBot"
git config --global user.email "cf-containerization@cloudfoundry.org"
git commit -m "Bump base docker image" --allow-empty
