# syntax=docker.io/docker/dockerfile:1.17

# see https://github.com/hashicorp/terraform/releases
# renovate: datasource=github-releases depName=hashicorp/terraform
ARG TERRAFORM_VERSION='1.12.2'

# see https://github.com/devcontainers/images/tree/main/src/base-debian/history
FROM mcr.microsoft.com/devcontainers/base:1.0.23-bookworm

RUN <<'EOF'
#!/usr/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y install --no-install-recommends \
    bash-completion \
    curl \
    git \
    libvirt-clients \
    mkisofs \
    openssh-client \
    python3-argcomplete \
    python3-libvirt \
    sudo \
    unzip \
    wget \
    xorriso \
    xsltproc
apt-get clean
rm -rf /var/lib/apt/lists/*
activate-global-python-argcomplete
EOF

ARG TERRAFORM_VERSION
ENV CHECKPOINT_DISABLE=1
RUN <<'EOF'
#!/usr/bin/bash
set -euxo pipefail
terraform_url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
t="$(mktemp -q -d --suffix=.terraform)"
wget -qO "$t/terraform.zip" "$terraform_url"
unzip "$t/terraform.zip" -d "$t"
install "$t/terraform" /usr/local/bin
rm -rf "$t"
terraform -install-autocomplete
EOF

RUN <<'EOF'
#!/usr/bin/bash
set -euxo pipefail
# ensure /etc/profile is called at the top of the file, when running in a
# login shell.
sed -i '0,/esac/s/esac/&\n\nsource \/etc\/profile/' /home/vscode/.bashrc
EOF
COPY inputrc /etc/inputrc
COPY login.sh /etc/profile.d/login.sh

ENV LIBVIRT_DEFAULT_URI='qemu:///system'
