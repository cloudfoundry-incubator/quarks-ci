# cf-operator-ci

## Pre-reqs
To fly one of the pipelines, a couple pre-req tools are required on your local machine:
- [`jq`](https://stedolan.github.io/jq/) is used in the convenience script (`fly-pipeline`)
- [`spruce`](https://github.com/geofffranks/spruce) is used to modify/insert parts into the final pipeline YAML (inlining scripts)
- [`fly`](https://concourse-ci.org/fly.html) to set the pipeline
- [`lpass`](https://github.com/lastpass/lastpass-cli) to retrieve secrets from the LastPass shared folder

Run `fly-pipeline` to get installation suggestions for your respective platform.


## Set a concourse pipeline
The convenience script `fly-pipeline` allows you to set your pipeline into an existing concourse server. Run it without any arguments to get a list of configured targets and available pipelines.

_First time users:_ You only need to do this once.
- Setup Concourse target to be used:
  ```
  fly --target flintstone login \
      --concourse-url=https://ci.flintstone.cf.cloud.ibm.com \
      --team-name=quarks
  ```
- Setup LassPass command line client:
  ```
  lpass login <your-lastpass-user>
  ```

_Note:_ Make sure you are logged in the Concourse target:
```
fly --target flintstone login
```

_Example:_
```
./fly-pipeline flintstone hello-world
```

## Pipeline directory structure
The pipelines must follow a simple contract in order to work with the convenience script `fly-pipeline`:
- A directory with the final pipeline name must be located under `pipelines` in the Git repo root.
- Inside the pipeline directory, there must be two files:
  - `pipeline.yml` contains the pipeline definition and supports Spruce operators, for example `(( file ... ))`.
  - `vars.yml` contains variables that are likely to be changed every once in a while, but not secrets.

You can find a pipeline example under `pipelines/hello-world`.

### Caveat

#### LastPass
In order to not have to explicitly specify each secret by key in the `fly` command, we use the _Notes_  section of one secret as a YAML and store the required secrets in there as one block. This keeps the `fly` command simple and allows for an easy way to add more secrets, however this also means that everybody has to use one LastPass site entry. The usage of CredHub would be preferred if possible in the future.

#### The containerization tag

In the existing concourse deployment, there are currently 2 workers with a tag by the name `containerization`. This is intended so that this 2 workers will host all the `cf-containerization` workload.

In order for your pipelines to be directed to these set of workers, you need to make use of the `tag` step modifier, please refer to the [tag documentation](https://concourse-ci.org/tags-step-modifier.html)


## Hostpath Volume Provisioning

Hostpath NFS volume provisioning is enabled in flintstone concourse-ci as it takes very less time for provisioning volumes and tests can be faster due to this. The [gist](https://gist.github.com/viovanov/f31529bc1575e3358bf6bb1de9fa495b) has the config that is used for enabling this.

## GOPROXY

We use [athens](https://github.com/gomods/athens) as a Go module proxy to speed up builds. It's deployed from as a helm chart in the `athens` namespace and it's URL is stored in the lastpass store. See [the documentation](https://docs.gomods.io/install/install-on-kubernetes/) for details on how to install it.

We use the node port installation so we can use it from all clusters, the goproxy URL in lastpass is made from `$NODE_IP:$NODE_PORT`.

```
helm install gomods/athens-proxy -n athens --namespace athens --set service.type=NodePort
export NODE_PORT=$(kubectl get --namespace athens -o jsonpath="{.spec.ports[0].nodePort}" services athens-athens-proxy)
export NODE_IP=$(kubectl get nodes --namespace athens -o jsonpath="{.items[0].status.addresses[0].address}")
```
