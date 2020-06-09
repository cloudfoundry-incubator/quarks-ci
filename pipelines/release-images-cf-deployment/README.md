# release-images-cf-deployment

This pipeline builds docker images for all the specified BOSH releases in a defined version of CF deployment.

* Reads stemcell version from s3 `cf-operators`
* Will error if new/outdated releases are found in the CF manifest
* Uploads release sources from CF deployment manifest to s3 `kubecf-sources`
* Does docker push to `cfcontainerization` if image is new
