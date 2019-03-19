FROM opensuse/leap:15

RUN zypper -n install --no-recommends make git docker zip curl gzip gcc ruby

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

RUN curl -fsL https://dl.google.com/go/go1.12.linux-amd64.tar.gz | tar -xz -C /opt && \
    update-alternatives --install "/usr/bin/go" "go" "/opt/go/bin/go" 1 && \
    update-alternatives --install "/usr/bin/gofmt" "gofmt" "/opt/go/bin/gofmt" 1

RUN go get -u golang.org/x/lint/golint
RUN go get github.com/onsi/ginkgo/ginkgo
RUN go get github.com/onsi/gomega/...

RUN zypper -n install --no-recommends kubectl

RUN curl -fsL https://clis.ng.bluemix.net/install/linux | sh && \
    bx plugin install container-service -r Bluemix && \
    bx plugin install container-registry -r Bluemix && \
    bx config --usage-stats-collect false && \
    bx config --check-version false

RUN gem install bosh-template