# release-images

This pipeline builds docker for the specified BOSH releases

* Downloads BOSH releases from different sources
* Uploads specified release sources to s3 `kubecf-sources`
* Does docker push to `cfcontainerization` if image is new
