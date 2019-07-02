# Setting up a BOSH Concourse deployment in Softlayer


## Requirements
- Clone of [cloudfoundry/bits-service-private-config](https://github.com/cloudfoundry/bits-service-private-config)
    - _**Note**_: This is the repo where all private information is stored. For both BOSH director and Concourse
- Clone of [concourse/concourse-bosh-deployment](https://github.com/concourse/concourse-bosh-deployment.git)(_**Note**_: using commit `162d0ae0d086e2a6881807768a41abae068ebbb1`)
- Spruce [binary](https://github.com/geofffranks/spruce/releases)


## Upload releases and stemcells
Currently using the following stemcells and releases version.

```
$ bosh upload-stemcell https://s3.amazonaws.com/bosh-softlayer-cpi-stemcells/light-bosh-stemcell-315.41-softlayer-xen-ubuntu-xenial-go_agent.tgz
$ bosh upload-release https://bosh.io/d/github.com/cloudfoundry/postgres-release?v=37
$ bosh upload-release https://bosh.io/d/github.com/cloudfoundry/bpm-release?v=1.0.4
$ bosh upload-release https://bosh.io/d/github.com/concourse/concourse-bosh-release?v=5.3.0
```



## Deploy concourse

```bash
pushd ~/workspace/concourse-bosh-deployment/cluster
bosh -d concourse deploy concourse.yml \
--vars-store ~/workspace/bits-service-private-config/environments/softlayer/concourse/concourse-green-vars.yml \
-l ../versions.yml \
-o operations/scale.yml \
-o ~/workspace/cf-operator-ci/operations/concourse-worker-quarks.yml \
-o ~/workspace/cf-operator-ci/operations/concourse-github-auth.yml \
--var web_instances=2 \
--var worker_instances=5 \
-o operations/basic-auth.yml \
--var local_user.username=admin \
--var local_user.password=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.concourseuser') \
--var github_client_id=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.github."client-id"') \
--var github_client_secret=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.github."client-secret"') \
--var external_url=https://ci.flintstone.cf.cloud.ibm.com  \
--var network_name=default \
--var web_vm_type=concourse-server \
--var worker_vm_type=concourse-worker \
--var deployment_name=concourse \
--var db_vm_type=concourse-server \
--var db_persistent_disk_type=200GB \
-o operations/external-postgres.yml \
-o operations/external-postgres-tls.yml \
-l ~/workspace/bits-service-private-config/environments/softlayer/concourse/postgres_ca_cert.yml \
--var postgres_host=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.concoursedb."host"') \
--var postgres_port=17376 \
--var postgres_role=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.concoursedb."user"')  \
--var postgres_password=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.concoursedb."password"') \
--no-redact
popd
```