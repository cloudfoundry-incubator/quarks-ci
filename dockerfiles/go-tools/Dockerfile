FROM opensuse/leap:15

RUN zypper -n install --no-recommends make git docker zip curl gzip gcc ruby vim jq unzip bind-utils

ADD https://github.com/SUSE/kctl/releases/download/v0.0.12/kctl-linux-amd64 /usr/bin/k

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

RUN curl -fsL https://dl.google.com/go/go1.12.2.linux-amd64.tar.gz | tar -xz -C /opt && \
    update-alternatives --install "/usr/bin/go" "go" "/opt/go/bin/go" 1 && \
    update-alternatives --install "/usr/bin/gofmt" "gofmt" "/opt/go/bin/gofmt" 1

RUN go get -u golang.org/x/lint/golint
RUN go get github.com/onsi/ginkgo/ginkgo
RUN go get github.com/onsi/gomega/...
RUN go get github.com/mattn/goveralls
RUN go get github.com/modocache/gover

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl; mv kubectl /usr/local/bin; chmod +x /usr/local/bin/kubectl

RUN curl -fsL https://clis.ng.bluemix.net/install/linux | sh && \
    bx plugin install container-service -r Bluemix && \
    bx plugin install container-registry -r Bluemix && \
    bx config --usage-stats-collect false && \
    bx config --check-version false

RUN gem install bosh-template
