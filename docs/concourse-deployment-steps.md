# Setting up a BOSH Concourse deployment in Softlayer


## Requirements
- Clone of [cloudfoundry/quarks-private](https://github.com/cloudfoundry/quarks-private.git)
    - _**Note**_: This is the repo where all private information is stored. For both BOSH director and Concourse
- Clone of [concourse/concourse-bosh-deployment](https://github.com/concourse/concourse-bosh-deployment.git)(_**Note**_: using commit `162d0ae0d086e2a6881807768a41abae068ebbb1`)
- Spruce [binary](https://github.com/geofffranks/spruce/releases)


## Upload releases and stemcells
Currently using the following stemcells and releases version.

```
$ bosh upload-stemcell --sha1 04799368e37cc5e577da4fc2c0e95632306e4e23 https://bosh.io/d/stemcells/bosh-softlayer-xen-ubuntu-xenial-go_agent?v=621.71
$ bosh upload-release --sha1 4488d08ff54117a9d904f6e2f27c82c1cf4c910e https://bosh.io/d/github.com/cloudfoundry/postgres-release?v=41
$ bosh upload-release --sha1 c956394fce7e74f741e4ae8c256b480904ad5942 https://bosh.io/d/github.com/cloudfoundry/bpm-release?v=1.1.8
$ bosh upload-release --sha1 476ede4062acab307440d8539d6270b2e8fb4c6d https://bosh.io/d/github.com/concourse/concourse-bosh-release?v=5.8.1
```

## Deploy concourse

```bash
pushd ~/workspace/concourse-bosh-deployment/cluster
bosh -d concourse-quarks deploy concourse.yml \
--vars-store ~/workspace/quarks-private/environments/softlayer/concourse/concourse-green-vars.yml \
-l ../versions.yml \
-o operations/scale.yml \
-o ~/workspace/cf-operator-ci/operations/concourse-worker-quarks.yml \
-o ~/workspace/cf-operator-ci/operations/concourse-github-auth.yml \
--var web_instances=2 \
--var worker_instances=5 \
--var github_client_id=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.github."client-id"') \
--var github_client_secret=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.github."client-secret"') \
--var external_url=https://ci.flintstone.cf.cloud.ibm.com  \
--var network_name=default \
--var web_vm_type=concourse-server \
--var worker_vm_type=concourse-worker \
--var deployment_name=concourse-quarks \
--var db_vm_type=concourse-server \
--var db_persistent_disk_type=200GB \
-o operations/external-postgres.yml \
-o operations/external-postgres-tls.yml \
-l ~/workspace/quarks-private/environments/softlayer/concourse/postgres_ca_cert.yml \
--var postgres_host=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.concoursedb."host"') \
--var postgres_port=17376 \
--var postgres_role=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.concoursedb."user"')  \
--var postgres_password=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.concoursedb."password"') \
--var azs=[z1] \
--no-redact
popd
```
