#!/usr/bin/env sh
set -ex

cp -a pr-src/. src/
cd src
git submodule update --init
