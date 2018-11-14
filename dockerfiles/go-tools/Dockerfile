FROM opensuse/leap:15

RUN zypper -n ar https://download.opensuse.org/repositories/devel:/languages:/go/openSUSE_Leap_15.0/ go \
  && zypper -n --gpg-auto-import-keys ref go
RUN zypper -n install --no-recommends make go1.11 docker

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

RUN go get -u golang.org/x/lint/golint
RUN go get github.com/onsi/ginkgo/ginkgo
RUN go get github.com/onsi/gomega/...
