FROM golang:1.13 AS build
WORKDIR /go/src/github.com/opendoor-labs/kube-bench/
COPY go.mod go.sum ./
COPY main.go .
COPY check/ check/
COPY cmd/ cmd/
ARG KUBEBENCH_VERSION
RUN GO111MODULE=on CGO_ENABLED=0 go install -a -ldflags "-X github.com/opendoor-labs/kube-bench/cmd.KubeBenchVersion=${KUBEBENCH_VERSION} -w"

FROM alpine:3.11 AS run
WORKDIR /opt/kube-bench/
# add GNU ps for -C, -o cmd, and --no-headers support
# https://github.com/aquasecurity/kube-bench/issues/109
RUN apk --no-cache add procps

# Openssl is used by OpenShift tests
# https://github.com/aquasecurity/kube-bench/issues/535
RUN apk --no-cache add openssl

# Add bash to execute cron jobs
RUN apk add --no-cache bash

ENV PATH=$PATH:/usr/local/mount-from-host/bin

COPY --from=build /go/bin/kube-bench /usr/local/bin/kube-bench
COPY entrypoint.sh .
COPY cfg/ cfg/
ENTRYPOINT ["./entrypoint.sh"]
CMD ["install"]

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="kube-bench" \
    org.label-schema.description="Run the CIS Kubernetes Benchmark tests" \
    org.label-schema.url="https://github.com/opendoor-labs/kube-bench" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/opendoor-labs/kube-bench" \
    org.label-schema.schema-version="1.0"
