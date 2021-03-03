# quarks-ci

## Pre-reqs

To fly one of the pipelines, a couple pre-req tools are required on your local machine:
- [`jq`](https://stedolan.github.io/jq/) is used in the convenience script (`fly-pipeline`)
- [`spruce`](https://github.com/geofffranks/spruce) is used to modify/insert parts into the final pipeline YAML (inlining scripts)
- [`fly`](https://concourse-ci.org/fly.html) to set the pipeline
- [`lpass`](https://github.com/lastpass/lastpass-cli) to retrieve secrets from the LastPass shared folder

Run `fly-pipeline` to get installation suggestions for your respective platform.


## Set a concourse pipeline (set-all.sh)

Uncomment pipelines you don't want to set, in case you're not setting all. Run

    ./set-all.sh fly-target

Run `expose-all.sh` to set pipelines public.

## Set a concourse pipeline (fly-pipeline)

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

## Concourse Quarks Team

First create the team, then create and expose the pipelines.

```
# Create teams
fly -t flintstone login -k -n admin -c https://ci.flintstone.cf.cloud.ibm.com/
fly -t flintstone set-team -n quarks --github-org=cloudfoundry-incubator:quarks

# Create pipelines
fly -t flintstone login -k -n quarks -c https://ci.flintstone.cf.cloud.ibm.com/
./set-all.sh flintstone
./expose-all.sh flintstone
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

### Deploying Athens Goproxy

We use [athens](https://github.com/gomods/athens) as a Go module proxy to speed up builds. It's deployed from as a helm chart in the `athens` namespace and it's URL is stored in the lastpass store. See [the documentation](https://docs.gomods.io/install/install-on-kubernetes/) for details on how to install it.

We use the node port installation so we can use it from all clusters, the goproxy URL in lastpass is made from `$NODE_IP:$NODE_PORT`.

```
#helm install gomods/athens-proxy -n athens --namespace athens --set service.type=NodePort
helm repo add gomods https://athens.blob.core.windows.net/charts
helm install athens gomods/athens-proxy --create-namespace --namespace athens --set service.type=NodePort

export NODE_PORT=$(kubectl get --namespace athens -o jsonpath="{.spec.ports[0].nodePort}" services athens-athens-proxy)
export NODE_IP=$(kubectl get nodes --namespace athens -o jsonpath="{.items[0].status.addresses[0].address}")
```

#### Issue with old Athens Helm Chart

Athens didn't update the Helm chart for their latest 0.10.0 release.
The old 0.9.0 release is using `extensions/v1beta1` instead of `apps/v1`: https://github.com/Drachenfels-GmbH/kubernetes-crio-lxc/issues/2#issuecomment-663580690


Fix up the old release and deploy from local dir:
```
helm pull gomods/athens-proxy
vi athens-proxy/templates/jaeger-deploy.yaml
helm install athens athens-proxy --create-namespace --namespace athens --set service.type=NodePort
```
