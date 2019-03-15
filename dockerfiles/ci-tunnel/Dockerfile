FROM sickp/alpine-sshd:latest

RUN passwd -d root

# Allow the reverse tunnel to bind to the public IP
RUN sed -i 's/#GatewayPorts no/GatewayPorts yes/' /etc/ssh/sshd_config

# Fix connection timeout issues
RUN sed -i 's/#TCPKeepAlive yes/TCPKeepAlive yes/;s/#ClientAliveInterval 0/ClientAliveInterval 120/;s/#ClientAliveCountMax 3/ClientAliveCountMax 15/' /etc/ssh/sshd_config

COPY identity.pub /root/.ssh/authorized_keys
