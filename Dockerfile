FROM ubuntu:24.04

# Set build-time arguments for build info
ARG BUILD_DATE
ARG VCS_REF
ARG PUID=0
ARG PGID=0
ENV BUILD_DATE=${BUILD_DATE}
ENV VCS_REF=${VCS_REF}
ENV PUID=${PUID}
ENV PGID=${PGID}

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    PASSWORD=password \
    PASSWORD_FILE="" \
    SHELL=bash

# Install base packages and dependencies in stages to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Essential system packages
    openssh-server \
    ca-certificates \
    curl \
    wget \
    unzip \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    # Core utilities
    git \
    nano \
    vim \
    neovim \
    tmux \
    screen \
    bash-completion \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    # File system support
    nfs-common \
    cifs-utils \
    fuse \
    # Archive tools
    p7zip-full \
    # Security tools
    openssl \
    gpg \
    # Data processing
    jq \
    # Database clients (minimal)
    postgresql-client \
    mysql-client \
    sqlite3 \
    # Programming languages
    python3 \
    python3-pip \
    python3-venv \
    # Network tools
    rsync \
    openssh-client \
    # Search and processing
    ripgrep \
    fzf \
    # Configuration management
    ansible \
    # HTTP tools
    httpie \
    # XML processing
    xmlstarlet \
    # Document processing
    pandoc \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install specific tools that require GitHub API calls with better error handling
# Use direct release download instead of install scripts where possible

# Install OpenTofu (Terraform alternative) - use official apt repository
RUN curl -fsSL https://get.opentofu.org/opentofu.gpg -o /etc/apt/keyrings/opentofu.gpg \
    && curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg \
    && chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" | tee /etc/apt/sources.list.d/opentofu.list \
    && apt-get update && apt-get install -y tofu \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl - use official repository
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
    && echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update && apt-get install -y kubectl \
    && rm -rf /var/lib/apt/lists/*

# Install Helm - use official repository
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update && apt-get install -y helm \
    && rm -rf /var/lib/apt/lists/*

# Install Kustomize - Fixed version to avoid GitHub API rate limits
RUN KUSTOMIZE_VERSION="v5.5.0" \
    && ARCH=$(dpkg --print-architecture) \
    && case $ARCH in \
        amd64) KUSTOMIZE_ARCH="linux_amd64" ;; \
        arm64) KUSTOMIZE_ARCH="linux_arm64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac \
    && wget -O kustomize.tar.gz "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_${KUSTOMIZE_ARCH}.tar.gz" \
    && tar -xzf kustomize.tar.gz \
    && mv kustomize /usr/local/bin/ \
    && chmod +x /usr/local/bin/kustomize \
    && rm kustomize.tar.gz

# Install Go (use fixed recent version to avoid API calls)
RUN GO_VERSION="1.23.4" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://golang.org/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-${ARCH}.tar.gz \
    && rm go${GO_VERSION}.linux-${ARCH}.tar.gz

# Add Go to PATH
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Node.js and npm (use NodeSource repository for specific version)
RUN NODE_VERSION="20" \
    && curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install MongoDB CLI tools
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg \
    && echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update && apt-get install -y mongodb-mongosh mongodb-database-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Redis CLI
RUN apt-get update && apt-get install -y redis-tools && rm -rf /var/lib/apt/lists/*

# Install tools with fixed versions to avoid GitHub API rate limits
# yq (YAML processor)
RUN YQ_VERSION="v4.44.3" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH} -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# xq (XML processor using yq)
RUN ln -s /usr/local/bin/yq /usr/local/bin/xq

# hcl2json for HCL processing
RUN HCL2JSON_VERSION="v0.6.3" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/tmccombs/hcl2json/releases/download/${HCL2JSON_VERSION}/hcl2json_linux_${ARCH} -O /usr/local/bin/hcl2json \
    && chmod +x /usr/local/bin/hcl2json

# htmlq for HTML processing
RUN HTMLQ_VERSION="v0.4.0" \
    && wget https://github.com/mgdm/htmlq/releases/download/${HTMLQ_VERSION}/htmlq-x86_64-linux.tar.gz \
    && tar -xzf htmlq-x86_64-linux.tar.gz \
    && mv htmlq /usr/local/bin/ \
    && rm htmlq-x86_64-linux.tar.gz

# dasel (universal data processor)
RUN DASEL_VERSION="v2.8.1" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/TomWright/dasel/releases/download/${DASEL_VERSION}/dasel_linux_${ARCH} -O /usr/local/bin/dasel \
    && chmod +x /usr/local/bin/dasel

# Install AWS CLI v2
RUN ARCH=$(dpkg --print-architecture) \
    && case $ARCH in \
        amd64) AWS_ARCH="x86_64" ;; \
        arm64) AWS_ARCH="aarch64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install Azure CLI
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg \
    && echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update && apt-get install -y azure-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Google Cloud CLI
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update && apt-get install -y google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# Install DigitalOcean CLI (doctl) - fixed version
RUN DOCTL_VERSION="1.117.0" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-${ARCH}.tar.gz \
    && tar xf doctl-${DOCTL_VERSION}-linux-${ARCH}.tar.gz \
    && mv doctl /usr/local/bin \
    && rm doctl-${DOCTL_VERSION}-linux-${ARCH}.tar.gz

# Install PowerShell
RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell \
    && rm packages-microsoft-prod.deb \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install containerd CLI tools - fixed version
RUN CONTAINERD_VERSION="1.7.22" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz \
    && tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz \
    && rm containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz

# Install nerdctl - fixed version
RUN NERDCTL_VERSION="1.7.7" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-${ARCH}.tar.gz \
    && tar Cxzvf /usr/local/bin nerdctl-${NERDCTL_VERSION}-linux-${ARCH}.tar.gz \
    && rm nerdctl-${NERDCTL_VERSION}-linux-${ARCH}.tar.gz

# Install crictl - fixed version
RUN CRICTL_VERSION="v1.31.1" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz \
    && tar zxvf crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz -C /usr/local/bin \
    && rm -f crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz

# Install kubectx and kubens
RUN git clone --depth 1 https://github.com/ahmetb/kubectx /opt/kubectx \
    && ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx \
    && ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install Pulumi
RUN PULUMI_VERSION="v3.140.0" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/pulumi/pulumi/releases/download/${PULUMI_VERSION}/pulumi-${PULUMI_VERSION}-linux-${ARCH}.tar.gz \
    && tar -xzf pulumi-${PULUMI_VERSION}-linux-${ARCH}.tar.gz \
    && mv pulumi/* /usr/local/bin/ \
    && rm -rf pulumi pulumi-${PULUMI_VERSION}-linux-${ARCH}.tar.gz

# Install Packer - fixed version
RUN PACKER_VERSION="1.11.2" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_${ARCH}.zip \
    && unzip packer_${PACKER_VERSION}_linux_${ARCH}.zip \
    && mv packer /usr/local/bin/ \
    && rm packer_${PACKER_VERSION}_linux_${ARCH}.zip

# Install Flux CLI - fixed version
RUN FLUX_VERSION="v2.4.0" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/fluxcd/flux2/releases/download/${FLUX_VERSION}/flux_${FLUX_VERSION:1}_linux_${ARCH}.tar.gz \
    && tar -xzf flux_${FLUX_VERSION:1}_linux_${ARCH}.tar.gz \
    && mv flux /usr/local/bin/ \
    && rm flux_${FLUX_VERSION:1}_linux_${ARCH}.tar.gz

# Install ArgoCD CLI - fixed version
RUN ARGO_VERSION="v2.13.1" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/argoproj/argo-cd/releases/download/${ARGO_VERSION}/argocd-linux-${ARCH} \
    && mv argocd-linux-${ARCH} /usr/local/bin/argocd \
    && chmod +x /usr/local/bin/argocd

# Install Jenkins CLI
RUN wget https://repo.jenkins-ci.org/public/org/jenkins-ci/main/cli/2.426/cli-2.426.jar -O /usr/local/bin/jenkins-cli.jar

# Install Skaffold - fixed version
RUN SKAFFOLD_VERSION="v2.13.2" \
    && ARCH=$(dpkg --print-architecture) \
    && curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/${SKAFFOLD_VERSION}/skaffold-linux-${ARCH} \
    && install skaffold /usr/local/bin/ \
    && rm skaffold

# Install SOPS - fixed version
RUN SOPS_VERSION="v3.9.1" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${ARCH} \
    && mv sops-${SOPS_VERSION}.linux.${ARCH} /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops

# Install OpenBao - fixed version
RUN OPENBAO_VERSION="2.1.0" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}/bao_${OPENBAO_VERSION}_linux_${ARCH}.deb \
    && dpkg -i bao_${OPENBAO_VERSION}_linux_${ARCH}.deb \
    && rm bao_${OPENBAO_VERSION}_linux_${ARCH}.deb

# Install pass (password manager)
RUN apt-get update && apt-get install -y pass && rm -rf /var/lib/apt/lists/*

# Install Prometheus promtool - fixed version
RUN PROMETHEUS_VERSION="2.55.1" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}.tar.gz \
    && tar xvfz prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}.tar.gz \
    && mv prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}/promtool /usr/local/bin/ \
    && rm -rf prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}*

# Install Nix package manager (single-user mode for container)
RUN sh <(curl -L https://nixos.org/nix/install) --no-daemon \
    && echo '. /root/.nix-profile/etc/profile.d/nix.sh' >> /root/.bashrc \
    && echo '. /root/.nix-profile/etc/profile.d/nix.sh' >> /root/.zshrc

# Install Talosctl - fixed version
RUN TALOS_VERSION="v1.8.3" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/talosctl-linux-${ARCH} \
    && mv talosctl-linux-${ARCH} /usr/local/bin/talosctl \
    && chmod +x /usr/local/bin/talosctl

# Install k9s - fixed version
RUN K9S_VERSION="v0.32.7" \
    && ARCH=$(dpkg --print-architecture) \
    && curl -sL https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz | tar xz -C /tmp \
    && mv /tmp/k9s /usr/local/bin/

# Install DynamoDB Local
RUN mkdir -p /opt/dynamodb \
    && curl -L https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz | tar xz -C /opt/dynamodb

# Install additional CLI tools via pip (minimal selection)
RUN pip3 install --no-cache-dir --break-system-packages \
    cqlsh \
    elasticsearch-cli

# Install etcd client (etcdctl) - fixed version
RUN ETCD_VER="v3.5.17" \
    && ARCH=$(dpkg --print-architecture) \
    && curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz \
    && tar xzf /tmp/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz -C /tmp \
    && mv /tmp/etcd-${ETCD_VER}-linux-${ARCH}/etcdctl /usr/local/bin/ \
    && rm -rf /tmp/etcd-${ETCD_VER}-linux-${ARCH}*

# Install mc (Midnight Commander)
RUN apt-get update && apt-get install -y mc && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Configure SSH
RUN mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Install Oh My Zsh for root
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Setup shell completions
RUN echo 'source /etc/bash_completion' >> /root/.bashrc \
    && echo 'source <(kubectl completion bash)' >> /root/.bashrc \
    && echo 'source <(helm completion bash)' >> /root/.bashrc \
    && echo 'source <(tofu -install-autocomplete)' >> /root/.bashrc 2>/dev/null || true \
    && echo 'complete -C aws_completer aws' >> /root/.bashrc \
    && echo 'source <(az completion bash)' >> /root/.bashrc \
    && echo 'source <(doctl completion bash)' >> /root/.bashrc \
    && echo 'source <(flux completion bash)' >> /root/.bashrc \
    && echo 'source <(argocd completion bash)' >> /root/.bashrc \
    && echo 'source <(bao -autocomplete-install)' >> /root/.bashrc 2>/dev/null || true

# Setup zsh completions
RUN echo 'autoload -U compinit && compinit' >> /root/.zshrc \
    && echo 'source <(kubectl completion zsh)' >> /root/.zshrc \
    && echo 'source <(helm completion zsh)' >> /root/.zshrc \
    && echo 'source <(talosctl completion zsh)' >> /root/.zshrc \
    && echo 'complete -C aws_completer aws' >> /root/.zshrc \
    && echo 'source <(az completion zsh)' >> /root/.zshrc \
    && echo 'source <(doctl completion zsh)' >> /root/.zshrc \
    && echo 'source <(flux completion zsh)' >> /root/.zshrc \
    && echo 'source <(argocd completion zsh)' >> /root/.zshrc \
    && echo 'source <(bao -autocomplete-install)' >> /root/.zshrc 2>/dev/null || true

# Create directories for mounted volumes
RUN mkdir -p /root/config /etc/fstab.d

# Copy entrypoint script and huh command
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY huh /usr/local/bin/huh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/huh

# Clean up to reduce image size
RUN apt-get autoremove -y \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# Expose SSH port
EXPOSE 22

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/usr/sbin/sshd", "-D"]