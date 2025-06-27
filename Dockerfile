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

# Install OpenTofu (Terraform alternative) - use official apt repository
RUN curl -fsSL https://get.opentofu.org/opentofu.gpg -o /etc/apt/keyrings/opentofu.gpg \
    && curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg \
    && chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" | tee /etc/apt/sources.list.d/opentofu.list \
    && apt-get update && apt-get install -y tofu \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform (can coexist with OpenTofu)
RUN for i in 1 2 3; do \
        TERRAFORM_VERSION=$(curl -s --fail https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r .tag_name | sed 's/v//') && break || sleep 30; \
    done \
    && if [ -z "$TERRAFORM_VERSION" ]; then \
        echo "Failed to get Terraform version, using fallback" && \
        TERRAFORM_VERSION="1.9.8"; \
    fi \
    && echo "Installing Terraform version: $TERRAFORM_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip

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

# Install Kustomize - Use GitHub API with retry logic to avoid rate limits
RUN for i in 1 2 3; do \
        KUSTOMIZE_VERSION=$(curl -s --fail https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest | jq -r .tag_name | sed 's/kustomize\///') && break || sleep 30; \
    done \
    && if [ -z "$KUSTOMIZE_VERSION" ]; then \
        echo "Failed to get Kustomize version, using fallback" && \
        KUSTOMIZE_VERSION="v5.5.0"; \
    fi \
    && echo "Installing Kustomize version: $KUSTOMIZE_VERSION" \
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

# Install Go (latest stable)
RUN for i in 1 2 3; do \
        GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1) && break || sleep 30; \
    done \
    && if [ -z "$GO_VERSION" ]; then \
        echo "Failed to get Go version, using fallback" && \
        GO_VERSION="go1.23.4"; \
    fi \
    && echo "Installing Go version: $GO_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://golang.org/dl/${GO_VERSION}.linux-${ARCH}.tar.gz \
    && tar -C /usr/local -xzf ${GO_VERSION}.linux-${ARCH}.tar.gz \
    && rm ${GO_VERSION}.linux-${ARCH}.tar.gz

# Add Go to PATH
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Node.js and npm (latest LTS)
RUN for i in 1 2 3; do \
        NODE_VERSION=$(curl -s https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)][0].version') && break || sleep 30; \
    done \
    && if [ -z "$NODE_VERSION" ]; then \
        echo "Failed to get Node.js version, using NodeSource repository" && \
        NODE_VERSION="20"; \
    fi \
    && if [[ "$NODE_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then \
        echo "Installing Node.js version: $NODE_VERSION" && \
        ARCH=$(dpkg --print-architecture) && \
        case $ARCH in \
            amd64) NODE_ARCH="x64" ;; \
            arm64) NODE_ARCH="arm64" ;; \
            *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
        esac && \
        curl -fsSL https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz | tar -xJ -C /usr/local --strip-components=1; \
    else \
        echo "Using NodeSource repository for Node.js" && \
        NODE_MAJOR="20" && \
        curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
        apt-get install -y nodejs && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Install MongoDB CLI tools
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg \
    && echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update && apt-get install -y mongodb-mongosh mongodb-database-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Redis CLI
RUN apt-get update && apt-get install -y redis-tools && rm -rf /var/lib/apt/lists/*

# Install tools with latest versions using GitHub API with retry logic
# yq (YAML processor)
RUN for i in 1 2 3; do \
        YQ_VERSION=$(curl -s --fail https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$YQ_VERSION" ]; then \
        echo "Failed to get yq version, using fallback" && \
        YQ_VERSION="v4.44.3"; \
    fi \
    && echo "Installing yq version: $YQ_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH} -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# xq (XML processor using yq)
RUN ln -s /usr/local/bin/yq /usr/local/bin/xq

# hcl2json for HCL processing
RUN for i in 1 2 3; do \
        HCL2JSON_VERSION=$(curl -s --fail https://api.github.com/repos/tmccombs/hcl2json/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$HCL2JSON_VERSION" ]; then \
        echo "Failed to get hcl2json version, using fallback" && \
        HCL2JSON_VERSION="v0.6.3"; \
    fi \
    && echo "Installing hcl2json version: $HCL2JSON_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/tmccombs/hcl2json/releases/download/${HCL2JSON_VERSION}/hcl2json_linux_${ARCH} -O /usr/local/bin/hcl2json \
    && chmod +x /usr/local/bin/hcl2json

# htmlq for HTML processing
RUN for i in 1 2 3; do \
        HTMLQ_VERSION=$(curl -s --fail https://api.github.com/repos/mgdm/htmlq/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$HTMLQ_VERSION" ]; then \
        echo "Failed to get htmlq version, using fallback" && \
        HTMLQ_VERSION="v0.4.0"; \
    fi \
    && echo "Installing htmlq version: $HTMLQ_VERSION" \
    && wget https://github.com/mgdm/htmlq/releases/download/${HTMLQ_VERSION}/htmlq-x86_64-linux.tar.gz \
    && tar -xzf htmlq-x86_64-linux.tar.gz \
    && mv htmlq /usr/local/bin/ \
    && rm htmlq-x86_64-linux.tar.gz

# dasel (universal data processor)
RUN for i in 1 2 3; do \
        DASEL_VERSION=$(curl -s --fail https://api.github.com/repos/TomWright/dasel/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$DASEL_VERSION" ]; then \
        echo "Failed to get dasel version, using fallback" && \
        DASEL_VERSION="v2.8.1"; \
    fi \
    && echo "Installing dasel version: $DASEL_VERSION" \
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

# Install DigitalOcean CLI (doctl) - latest version
RUN for i in 1 2 3; do \
        DOCTL_VERSION=$(curl -s --fail https://api.github.com/repos/digitalocean/doctl/releases/latest | jq -r .tag_name | sed 's/v//') && break || sleep 30; \
    done \
    && if [ -z "$DOCTL_VERSION" ]; then \
        echo "Failed to get doctl version, using fallback" && \
        DOCTL_VERSION="1.117.0"; \
    fi \
    && echo "Installing doctl version: $DOCTL_VERSION" \
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

# Install containerd CLI tools - latest version
RUN for i in 1 2 3; do \
        CONTAINERD_VERSION=$(curl -s --fail https://api.github.com/repos/containerd/containerd/releases/latest | jq -r .tag_name | sed 's/v//') && break || sleep 30; \
    done \
    && if [ -z "$CONTAINERD_VERSION" ]; then \
        echo "Failed to get containerd version, using fallback" && \
        CONTAINERD_VERSION="1.7.22"; \
    fi \
    && echo "Installing containerd version: $CONTAINERD_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz \
    && tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz \
    && rm containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz

# Install nerdctl - latest version
RUN for i in 1 2 3; do \
        NERDCTL_VERSION=$(curl -s --fail https://api.github.com/repos/containerd/nerdctl/releases/latest | jq -r .tag_name | sed 's/v//') && break || sleep 30; \
    done \
    && if [ -z "$NERDCTL_VERSION" ]; then \
        echo "Failed to get nerdctl version, using fallback" && \
        NERDCTL_VERSION="1.7.7"; \
    fi \
    && echo "Installing nerdctl version: $NERDCTL_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-${ARCH}.tar.gz \
    && tar Cxzvf /usr/local/bin nerdctl-${NERDCTL_VERSION}-linux-${ARCH}.tar.gz \
    && rm nerdctl-${NERDCTL_VERSION}-linux-${ARCH}.tar.gz

# Install crictl - latest version
RUN for i in 1 2 3; do \
        CRICTL_VERSION=$(curl -s --fail https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$CRICTL_VERSION" ]; then \
        echo "Failed to get crictl version, using fallback" && \
        CRICTL_VERSION="v1.31.1"; \
    fi \
    && echo "Installing crictl version: $CRICTL_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz \
    && tar zxvf crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz -C /usr/local/bin \
    && rm -f crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz

# Install kubectx and kubens
RUN git clone --depth 1 https://github.com/ahmetb/kubectx /opt/kubectx \
    && ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx \
    && ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install Pulumi - latest version
RUN for i in 1 2 3; do \
        PULUMI_VERSION=$(curl -s --fail https://api.github.com/repos/pulumi/pulumi/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$PULUMI_VERSION" ]; then \
        echo "Failed to get Pulumi version, using fallback" && \
        PULUMI_VERSION="v3.140.0"; \
    fi \
    && echo "Installing Pulumi version: $PULUMI_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/pulumi/pulumi/releases/download/${PULUMI_VERSION}/pulumi-${PULUMI_VERSION}-linux-${ARCH}.tar.gz \
    && tar -xzf pulumi-${PULUMI_VERSION}-linux-${ARCH}.tar.gz \
    && mv pulumi/* /usr/local/bin/ \
    && rm -rf pulumi pulumi-${PULUMI_VERSION}-linux-${ARCH}.tar.gz

# Install Packer - latest version
RUN for i in 1 2 3; do \
        PACKER_VERSION=$(curl -s --fail https://api.github.com/repos/hashicorp/packer/releases/latest | jq -r .tag_name | sed 's/v//') && break || sleep 30; \
    done \
    && if [ -z "$PACKER_VERSION" ]; then \
        echo "Failed to get Packer version, using fallback" && \
        PACKER_VERSION="1.11.2"; \
    fi \
    && echo "Installing Packer version: $PACKER_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_${ARCH}.zip \
    && unzip packer_${PACKER_VERSION}_linux_${ARCH}.zip \
    && mv packer /usr/local/bin/ \
    && rm packer_${PACKER_VERSION}_linux_${ARCH}.zip

# Install Flux CLI - latest version
RUN for i in 1 2 3; do \
        FLUX_VERSION=$(curl -s --fail https://api.github.com/repos/fluxcd/flux2/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$FLUX_VERSION" ]; then \
        echo "Failed to get Flux version, using fallback" && \
        FLUX_VERSION="v2.4.0"; \
    fi \
    && echo "Installing Flux version: $FLUX_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/fluxcd/flux2/releases/download/${FLUX_VERSION}/flux_${FLUX_VERSION:1}_linux_${ARCH}.tar.gz \
    && tar -xzf flux_${FLUX_VERSION:1}_linux_${ARCH}.tar.gz \
    && mv flux /usr/local/bin/ \
    && rm flux_${FLUX_VERSION:1}_linux_${ARCH}.tar.gz

# Install ArgoCD CLI - latest version
RUN for i in 1 2 3; do \
        ARGO_VERSION=$(curl -s --fail https://api.github.com/repos/argoproj/argo-cd/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$ARGO_VERSION" ]; then \
        echo "Failed to get ArgoCD version, using fallback" && \
        ARGO_VERSION="v2.13.1"; \
    fi \
    && echo "Installing ArgoCD version: $ARGO_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/argoproj/argo-cd/releases/download/${ARGO_VERSION}/argocd-linux-${ARCH} \
    && mv argocd-linux-${ARCH} /usr/local/bin/argocd \
    && chmod +x /usr/local/bin/argocd

# Install Jenkins CLI
RUN wget https://repo.jenkins-ci.org/public/org/jenkins-ci/main/cli/2.426/cli-2.426.jar -O /usr/local/bin/jenkins-cli.jar

# Install Skaffold - latest version
RUN for i in 1 2 3; do \
        SKAFFOLD_VERSION=$(curl -s --fail https://api.github.com/repos/GoogleContainerTools/skaffold/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$SKAFFOLD_VERSION" ]; then \
        echo "Failed to get Skaffold version, using fallback" && \
        SKAFFOLD_VERSION="v2.13.2"; \
    fi \
    && echo "Installing Skaffold version: $SKAFFOLD_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/${SKAFFOLD_VERSION}/skaffold-linux-${ARCH} \
    && install skaffold /usr/local/bin/ \
    && rm skaffold

# Install SOPS - latest version
RUN for i in 1 2 3; do \
        SOPS_VERSION=$(curl -s --fail https://api.github.com/repos/getsops/sops/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$SOPS_VERSION" ]; then \
        echo "Failed to get SOPS version, using fallback" && \
        SOPS_VERSION="v3.9.1"; \
    fi \
    && echo "Installing SOPS version: $SOPS_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${ARCH} \
    && mv sops-${SOPS_VERSION}.linux.${ARCH} /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops

# Install OpenBao - latest version
RUN for i in 1 2 3; do \
        OPENBAO_VERSION=$(curl -s --fail https://api.github.com/repos/openbao/openbao/releases/latest | jq -r .tag_name | sed 's/v//') && break || sleep 30; \
    done \
    && if [ -z "$OPENBAO_VERSION" ]; then \
        echo "Failed to get OpenBao version, using fallback" && \
        OPENBAO_VERSION="2.1.0"; \
    fi \
    && echo "Installing OpenBao version: $OPENBAO_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}/bao_${OPENBAO_VERSION}_linux_${ARCH}.deb \
    && dpkg -i bao_${OPENBAO_VERSION}_linux_${ARCH}.deb \
    && rm bao_${OPENBAO_VERSION}_linux_${ARCH}.deb

# Install HashiCorp Vault (can coexist with OpenBao)
RUN for i in 1 2 3; do \
        VAULT_VERSION=$(curl -s --fail https://api.github.com/repos/hashicorp/vault/releases/latest | jq -r .tag_name | sed 's/v//') && break || sleep 30; \
    done \
    && if [ -z "$VAULT_VERSION" ]; then \
        echo "Failed to get Vault version, using fallback" && \
        VAULT_VERSION="1.17.7"; \
    fi \
    && echo "Installing Vault version: $VAULT_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip \
    && unzip vault_${VAULT_VERSION}_linux_${ARCH}.zip \
    && mv vault /usr/local/bin/ \
    && rm vault_${VAULT_VERSION}_linux_${ARCH}.zip

# Install pass (password manager)
RUN apt-get update && apt-get install -y pass && rm -rf /var/lib/apt/lists/*

# Install Prometheus promtool - latest version
RUN for i in 1 2 3; do \
        PROMETHEUS_VERSION=$(curl -s --fail https://api.github.com/repos/prometheus/prometheus/releases/latest | jq -r .tag_name | sed 's/v//') && break || sleep 30; \
    done \
    && if [ -z "$PROMETHEUS_VERSION" ]; then \
        echo "Failed to get Prometheus version, using fallback" && \
        PROMETHEUS_VERSION="2.55.1"; \
    fi \
    && echo "Installing Prometheus promtool version: $PROMETHEUS_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}.tar.gz \
    && tar xvfz prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}.tar.gz \
    && mv prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}/promtool /usr/local/bin/ \
    && rm -rf prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}*

# Install Nix package manager (single-user mode for container)
RUN sh <(curl -L https://nixos.org/nix/install) --no-daemon \
    && echo '. /root/.nix-profile/etc/profile.d/nix.sh' >> /root/.bashrc \
    && echo '. /root/.nix-profile/etc/profile.d/nix.sh' >> /root/.zshrc

# Install Talosctl - latest version
RUN for i in 1 2 3; do \
        TALOS_VERSION=$(curl -s --fail https://api.github.com/repos/siderolabs/talos/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$TALOS_VERSION" ]; then \
        echo "Failed to get Talos version, using fallback" && \
        TALOS_VERSION="v1.8.3"; \
    fi \
    && echo "Installing Talosctl version: $TALOS_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && wget https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/talosctl-linux-${ARCH} \
    && mv talosctl-linux-${ARCH} /usr/local/bin/talosctl \
    && chmod +x /usr/local/bin/talosctl

# Install k9s - latest version
RUN for i in 1 2 3; do \
        K9S_VERSION=$(curl -s --fail https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$K9S_VERSION" ]; then \
        echo "Failed to get k9s version, using fallback" && \
        K9S_VERSION="v0.32.7"; \
    fi \
    && echo "Installing k9s version: $K9S_VERSION" \
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

# Install etcd client (etcdctl) - latest version
RUN for i in 1 2 3; do \
        ETCD_VER=$(curl -s --fail https://api.github.com/repos/etcd-io/etcd/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$ETCD_VER" ]; then \
        echo "Failed to get etcd version, using fallback" && \
        ETCD_VER="v3.5.17"; \
    fi \
    && echo "Installing etcdctl version: $ETCD_VER" \
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

# Setup shell completions and aliases
RUN echo 'source /etc/bash_completion' >> /root/.bashrc \
    && echo 'source <(kubectl completion bash)' >> /root/.bashrc \
    && echo 'source <(helm completion bash)' >> /root/.bashrc \
    && echo 'source <(tofu -install-autocomplete)' >> /root/.bashrc 2>/dev/null || true \
    && echo 'source <(terraform -install-autocomplete)' >> /root/.bashrc 2>/dev/null || true \
    && echo 'complete -C aws_completer aws' >> /root/.bashrc \
    && echo 'source <(az completion bash)' >> /root/.bashrc \
    && echo 'source <(doctl completion bash)' >> /root/.bashrc \
    && echo 'source <(flux completion bash)' >> /root/.bashrc \
    && echo 'source <(argocd completion bash)' >> /root/.bashrc \
    && echo 'source <(talosctl completion bash)' >> /root/.bashrc \
    && echo 'source <(bao -autocomplete-install)' >> /root/.bashrc 2>/dev/null || true \
    && echo 'source <(vault -autocomplete-install)' >> /root/.bashrc 2>/dev/null || true \
    && echo '' >> /root/.bashrc \
    && echo '# Custom aliases with autocomplete' >> /root/.bashrc \
    && echo 'alias k="kubectl"' >> /root/.bashrc \
    && echo 'alias t="talosctl"' >> /root/.bashrc \
    && echo 'alias h="helm"' >> /root/.bashrc \
    && echo 'alias kz="kustomize"' >> /root/.bashrc \
    && echo 'alias fcd="flux"' >> /root/.bashrc \
    && echo 'alias acd="argocd"' >> /root/.bashrc \
    && echo 'alias ot="tofu"' >> /root/.bashrc \
    && echo 'alias tf="terraform"' >> /root/.bashrc \
    && echo 'alias v="vault"' >> /root/.bashrc \
    && echo '' >> /root/.bashrc \
    && echo '# Alias autocomplete setup' >> /root/.bashrc \
    && echo 'complete -o default -F __start_kubectl k' >> /root/.bashrc \
    && echo 'complete -o default -F _cli_bash_autocomplete t' >> /root/.bashrc \
    && echo 'complete -o default -F _helm h' >> /root/.bashrc \
    && echo 'complete -o default -F _cli_bash_autocomplete fcd' >> /root/.bashrc \
    && echo 'complete -o default -F _cli_bash_autocomplete acd' >> /root/.bashrc

# Setup zsh completions and aliases
RUN echo 'autoload -U compinit && compinit' >> /root/.zshrc \
    && echo 'source <(kubectl completion zsh)' >> /root/.zshrc \
    && echo 'source <(helm completion zsh)' >> /root/.zshrc \
    && echo 'source <(talosctl completion zsh)' >> /root/.zshrc \
    && echo 'source <(flux completion zsh)' >> /root/.zshrc \
    && echo 'source <(argocd completion zsh)' >> /root/.zshrc \
    && echo 'complete -C aws_completer aws' >> /root/.zshrc \
    && echo 'source <(az completion zsh)' >> /root/.zshrc \
    && echo 'source <(doctl completion zsh)' >> /root/.zshrc \
    && echo 'source <(bao -autocomplete-install)' >> /root/.zshrc 2>/dev/null || true \
    && echo 'source <(vault -autocomplete-install)' >> /root/.zshrc 2>/dev/null || true \
    && echo '' >> /root/.zshrc \
    && echo '# Custom aliases with autocomplete' >> /root/.zshrc \
    && echo 'alias k="kubectl"' >> /root/.zshrc \
    && echo 'alias t="talosctl"' >> /root/.zshrc \
    && echo 'alias h="helm"' >> /root/.zshrc \
    && echo 'alias kz="kustomize"' >> /root/.zshrc \
    && echo 'alias fcd="flux"' >> /root/.zshrc \
    && echo 'alias acd="argocd"' >> /root/.zshrc \
    && echo 'alias ot="tofu"' >> /root/.zshrc \
    && echo 'alias tf="terraform"' >> /root/.zshrc \
    && echo 'alias v="vault"' >> /root/.zshrc \
    && echo '' >> /root/.zshrc \
    && echo '# Alias autocomplete setup' >> /root/.zshrc \
    && echo 'compdef k=kubectl' >> /root/.zshrc \
    && echo 'compdef t=talosctl' >> /root/.zshrc \
    && echo 'compdef h=helm' >> /root/.zshrc \
    && echo 'compdef fcd=flux' >> /root/.zshrc \
    && echo 'compdef acd=argocd' >> /root/.zshrc \
    && echo 'compdef ot=tofu' >> /root/.zshrc \
    && echo 'compdef tf=terraform' >> /root/.zshrc \
    && echo 'compdef v=vault' >> /root/.zshrc

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