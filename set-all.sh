./fly-pipeline cfo cf-operator
./fly-pipeline cfo cf-operator-check
./fly-pipeline cfo cf-operator-nightly
./fly-pipeline cfo cf-operator-testing-image
./fly-pipeline cfo release-images
./fly-pipeline cfo release-images-cf-deployment
./fly-pipeline cfo quarks-gora
./fly-pipeline cfo images

pushd pipelines/cf-operator-release
  ./configure.sh cfo v4.0.x v4.
  ./configure.sh cfo v5.0.x v5.
popd
