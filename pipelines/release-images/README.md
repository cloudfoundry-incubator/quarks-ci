# release-images

This pipeline builds docker images for the specified BOSH releases.

* Monitors changes to bosh.io releases, releases on s3, fissile and the stemcell
* Downloads BOSH releases from bosh.io or s3
* Uploads specified release sources to s3 `kubecf-sources`
* Does docker push to `cfcontainerization` if image is new
