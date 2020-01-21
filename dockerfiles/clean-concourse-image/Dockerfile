FROM ubuntu:latest

RUN apt update
RUN apt -y install wget

RUN wget https://support.arraynetworks.net/prx/001/http/supportportal.arraynetworks.net/downloads/pkg_9_4_0_305/MP_Linux_1.2.5/MotionPro_Linux_Ubuntu_x64_v1.2.5.sh -O vpn_client.sh --no-check-certificate
RUN printf '%s\n' '#!/bin/bash' 'exit 0' | tee -a /etc/rc.local
RUN chmod +x /etc/rc.local
RUN chmod +x ./vpn_client.sh
RUN ./vpn_client.sh

RUN wget https://github.com/cloudfoundry/bosh-cli/releases/download/v6.1.1/bosh-cli-6.1.1-linux-amd64 -O bosh
RUN chmod +x ./bosh
RUN mv ./bosh /usr/local/bosh
