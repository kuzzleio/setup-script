#!/bin/bash

set -e

install_via_apt() {
    apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg2 \
      lsb-release \
      software-properties-common

    curl -fsSL https://download.docker.com/linux/$(lsb_release -si | tr 'A-Z' 'a-z')/gpg | apt-key add -

    add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -si | tr 'A-Z' 'a-z') \
    $(lsb_release -cs) \
    stable"

    apt-get update

    apt-get install -y docker-ce
}

install_via_dnf() {
    dnf install -yq dnf-plugins-core

    dnf config-manager -q \
        --add-repo \
        https://download.docker.com/linux/fedora/docker-ce.repo
    
    dnf install -yq docker-ce
}

if [ $(command -v apt-get) ]; then
    install_via_apt
    exit 0
fi

if [ $(command -v dnf) ]; then
    install_via_dnf
    exit 0
fi
