FROM cfcontainerization/base-ci:latest

ADD https://github.com/SUSE/kctl/releases/download/v0.0.12/kctl-linux-amd64 /usr/bin/k
RUN chmod +x /usr/bin/k

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

RUN curl -fsL https://dl.google.com/go/go1.14.7.linux-amd64.tar.gz | tar -xz -C /opt && \
    update-alternatives --install "/usr/bin/go" "go" "/opt/go/bin/go" 1 && \
    update-alternatives --install "/usr/bin/gofmt" "gofmt" "/opt/go/bin/gofmt" 1

RUN go get -u golang.org/x/lint/golint
RUN go get github.com/onsi/ginkgo/ginkgo
RUN go get github.com/onsi/gomega/...
RUN go get github.com/rohitsakala/goveralls
RUN go get github.com/modocache/gover
RUN go get honnef.co/go/tools/cmd/staticcheck && cd $GOPATH/src/honnef.co/go/tools/cmd/staticcheck && git checkout 2019.2.2 && go get && go install

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl; mv kubectl /usr/local/bin; chmod +x /usr/local/bin/kubectl

RUN curl -sL https://raw.githubusercontent.com/homeport/havener/master/scripts/download-latest.sh | bash

RUN curl -fsL https://clis.ng.bluemix.net/install/linux | sh && \
    bx plugin install container-service -r Bluemix && \
    bx plugin install container-registry -r Bluemix && \
    bx config --usage-stats-collect false && \
    bx config --check-version false

RUN gem install bosh-template
RUN pip3 install git-pull-request

ENV HELM_VERSION="v3.1.2"
ENV HELM_URL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
RUN curl --progress-bar --location ${HELM_URL} | tar -xzf - -C /tmp linux-amd64/helm && \
    mv /tmp/linux-amd64/helm /usr/bin/helm && \
    rm -rf /tmp/linux-amd64/

RUN wget https://github.com/cloudfoundry/bosh-cli/releases/download/v6.1.1/bosh-cli-6.1.1-linux-amd64 -O bosh
RUN chmod +x ./bosh
RUN mv ./bosh /usr/local/bin/bosh
