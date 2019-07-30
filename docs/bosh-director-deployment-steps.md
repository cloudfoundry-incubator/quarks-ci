
# Setting up a BOSH director in Softlayer

The current `https://ci.flintstone.cf.cloud.ibm.com/` server, runs as a bosh deployment inside 
a bosh director in Softlayer.

The following document, layout the requirements and steps that needs to be executed, in order to create a suitable
director environment in an specific Softlayer account.


_**Note**_:  Softlayer is the IaaS used in IBM, where most of the IBM Cloud infrastructure runs.


## Requirements
- Clone of [mattcui/bosh-deployment](https://ci.flintstone.cf.cloud.ibm.com/)(_**Note**_: using commit `0642d45cdcd2ccc82deccc547913721d5845f472`)
    - _**Note**_: This could also have worked with [official bosh deployment](https://github.com/cloudfoundry/bosh-deployment), but it was not used.
- Clone of [cloudfoundry/bosh-softlayer-cpi-release](https://github.com/cloudfoundry/bosh-softlayer-cpi-release)
- Clone of [cloudfoundry/quarks-private.git](https://github.com/cloudfoundry/quarks-private.git)
    - _**Note**_: This is the repo where all private information is stored. For both BOSH director and Concourse
    deployment.
- Spruce [binary](https://github.com/geofffranks/spruce/releases)
- An specific customize BOSH cli. Required for the Softlayer CPI, to read an specific VM IP.
    ```bash
    # For Linux
    $ wget -O /usr/bin/bosh2 https://s3.amazonaws.com/bosh-softlayer-artifacts/bosh-cli-5.4.0.1-softlayer-linux-amd64 &&    chmod +x /usr/bin/bosh2

    # Fpr Darwin
    $ wget -O /usr/bin/bosh2 https://s3.amazonaws.com/bosh-softlayer-artifacts/bosh-cli-5.4.0.1-softlayer-darwin-amd64 &&   chmod +x /usr/bin/bosh2
    ```

## Deploying the BOSH director

### Create a VM in SL


- Run the `create_vm_sl.sh` script(_**Note**_: If you already have a director VM, do NOT run this script):
    ```bash
    $ pushd ~/workspace/bosh-softlayer-cpi-release/docs
    $ ./create_vm_sl.sh -h director-green -d bits.ams -c 4 -m 8192 -hb true -dc <dc> -uv <public_vlan> -iv <private_vlan> -u flintstone@cloudfoundry.org  -k <account_api_key>  > director-state.json
    $ popd
    ```
- The `director-state.json`, contains a VM `CID` and `IP` we will require to add this values later into a JSON file.


### Update environment bosh-green-state.json
The `bosh-green-state.json` file, is an state file that helps the `bosh create-env` command,
to remember resources it creates in the IaaS, so that it can re-use or delete them later.

- Move into the `cloudfoundry/quarks-private.git`
    ```bash
    $ pushd ~/workspace/quarks-private/environments/softlayer/director
    ```
- Modify the `bosh-green-state.json` file, by adding the following keys, with the values from the previous generated
`director-state.json` file(_**Note**_: If you already have a director VM, do NOT modify anything in this file).
    ```bash
    current_vm_cid: <CID from director-state.json>
    current_ip: <IP from director-state.json>
    ```

### Run the BOSH create-env cmd

- Set the following environment variables, so that during the creation,
we can grab some CPI logs, in case we require to debug the task.
    ```bash
    $ export BOSH_LOG_LEVEL=DEBUG
    $ export BOSH_LOG_PATH=./run.log
    ```
- Run the BOSH interpolation
    ```bash
    $ pushd ~/workspace/quarks-private/environments/softlayer/director
    $ bosh interpolate ~/workspace/bosh-deployment/bosh.yml \
        --vars-store=green-vars.yml \
        -o ~/workspace/bosh-deployment/softlayer/cpi-dynamic.yml \
        -o ~/workspace/bosh-deployment/misc/powerdns.yml \
        -o ~/workspace/bosh-deployment/jumpbox-user.yml \
        -v internal_ip=<IP_OF_NEW_VM> \
        -v sl_username=flintstone@cloudfoundry.org \
        -v sl_api_key=<SL_APIKEY>\
        -v sl_datacenter=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.director."dc"') \
        -v sl_vlan_private=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.director."privatevlan"') \
        -v sl_vlan_public=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" show --notes | spruce json | jq -r '.director."publicvlan"') \
        -v sl_vm_name_prefix=director-green \
        -v sl_vm_domain=bits.ams \
        -v dns_recursor_ip=8.8.8.8 \
        -v director_name=bosh \
        -o ~/workspace/cf-operator-ci/operations/use-softlayer-cpi-v35.yml \
        > bosh-green-new.yml
    ```
    _**Note**_: The ~/workspace/bosh-deployment/misc/powerdns.yml, contains an ops call
    for `/networks/name=default/subnets/0/dns` that could lead to issues during interpolation,
    comment it out if this is the case. 

- Run the `create-env` cmd
    ```bash
    $ sudo bosh create-env --state bosh-green-state.json --vars-store green-vars.yml bosh-green-new.yml
    ```

- Source environment variables
    ```bash
    $ direnv allow
    $ popd
    ```

## Update the cloud-config

Now that you have access to the green bosh director.

```bash
$ bosh update-cloud-config ~/workspace/quarks-private/environments/softlayer/director/cloud-config.yml
```
