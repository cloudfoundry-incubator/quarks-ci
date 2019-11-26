# Restarting CI Workers

Whenever the pipelines fail in a weird manner in CI, that means there is some high load on the workers. We need to restart the concourse workers to fix it.

## Steps

### VPN Username & Password
- Open [link](https://cloud.ibm.com/iam/users/IBMid-550004EMJ7?tab=userdetails) and find your VPN username and password under **VPN password** section.

### Running VPN

#### Windows
- Open [link](https://vpn.ams01.softlayer.com/prx/000/http/localhost/login) in the Internet Explorer browser.
- Login using the username and password and click connect.

#### Ubuntu
- Install MotionPro client using the following commands
```
wget https://support.arraynetworks.net/prx/001/http/supportportal.arraynetworks.net/downloads/pkg_9_4_0_305/MP_Linux_1.2.5/MotionPro_Linux_Ubuntu_x64_v1.2.5.sh -O vpn_client.sh --no-check-certificate
printf '%s\n' '#!/bin/bash' 'exit 0' | sudo tee -a /etc/rc.local
sudo chmod +x /etc/rc.local
chmod +x ./vpn_client.sh
sudo ./vpn_client.sh
MotionPro --host vpn.lon04.softlayer.com --user your_username --passwd your_password
```

### Install Bosh CLI from 

```
wget https://github.com/cloudfoundry/bosh-cli/releases/download/v6.1.1/bosh-cli-6.1.1-linux-amd64 -O bosh
chmod +x ./bosh
sudo mv ./bosh /usr/local/bosh
```

### Accessing Bosh Deployment
- Run the following commands to access the bosh deployments
```
git clone https://github.com/cloudfoundry/quarks-private
cd quarks-private/environments/softlayer/director
source .envrc
bosh deployments
```

### Restarting a worker
- Find the worker you want to restart by checking the vitals [load, mem usage, disk usage etc] of the workers using the following command
```
bosh vms --vitals
```
- Stop the worker
```
bosh -d concourse stop worker/4f88a295-4d7a-4d2b-8c5d-ad3faadb1d9f
```
- Reboot the worker
```
bosh -d concourse ssh worker/4f88a295-4d7a-4d2b-8c5d-ad3faadb1d9f
sudo su  
monit summary  
reboot now
```
- Clean the worker
```
sudo su  
rm -rf /var/vcap/data/worker
```
- Start the worker
```
bosh -d concourse start worker/4f88a295-4d7a-4d2b-8c5d-ad3faadb1d9f
```
