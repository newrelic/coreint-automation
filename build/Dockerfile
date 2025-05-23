ARG UBUNTU_VERSION=16.04

# Use Ubuntu as the base image
FROM ubuntu:${UBUNTU_VERSION}

ARG GO_VERSION=1.23.2
ARG ARCH='amd64'
ARG GH_VERSION='2.61.0'
ARG DOCKER_VERSION='24.0.5'
ARG BUILDX_VERSION='0.11.2'

# Install dependencies
RUN apt-get update && apt-get install -y \
    gnupg-agent \
    unzip \
    zip \
    curl \
    wget \
    expect \
    git \
    tar \
    gcc \
    jq \
    g++ \
    gnupg2 \
    gnupg-agent \
    debsigs \
    rpm \
    build-essential \
    software-properties-common \
    python-software-properties \
    gcc-arm-linux-gnueabi \
    dpkg-sig \
    gcc-aarch64-linux-gnu

# Install Go
RUN curl -sSL https://golang.org/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz -o go${GO_VERSION}.linux-${ARCH}.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-${ARCH}.tar.gz && \
    rm go${GO_VERSION}.linux-${ARCH}.tar.gz

# Set Go environment variables
ENV PATH="/usr/local/go/bin:/go/bin:${PATH}"
ENV GOPATH="/go"

# Default value of -buildvcs is auto, more info:
# https://github.com/kubernetes-sigs/gateway-api/pull/2302#issuecomment-1855818388
ENV GOFLAGS="-buildvcs=false"

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz -o docker.tgz && \
    tar --extract --file docker.tgz --strip-components 1 --directory /usr/local/bin/ && \
    rm docker.tgz

# Install Buildx
RUN mkdir -p ~/.docker/cli-plugins && \
    curl -sSL https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-${ARCH} -o ~/.docker/cli-plugins/docker-buildx && \
    chmod +x ~/.docker/cli-plugins/docker-buildx

# Since the user does not match the owners of the repo "git rev-parse --is-inside-work-tree" fails and goreleaser does not populate projectName
# https://stackoverflow.com/questions/72978485/git-submodule-update-failed-with-fatal-detected-dubious-ownership-in-repositor
RUN git config --global --add safe.directory '*'
COPY ./build/sign.sh ./build/sign_deb.exp ./build/sign_rpm.exp ./build/sign_tar.exp /usr/local/bin/
RUN curl -L https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.deb -o gh_${GH_VERSION}_linux_amd64.deb
RUN dpkg -i gh_${GH_VERSION}_linux_amd64.deb
