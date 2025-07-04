FROM archlinux:latest

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
ENV TZ=UTC \
    PASSWORD=password \
    PASSWORD_FILE="" \
    SHELL=bash \
    MAC=0D:EC:AF:C0:FF:EE \
    IP_ADDRESS="" \
    IP_ADDRESS6="" \
    IP_GATEWAY="" \
    IP_GATEWAY6="" \
    IP_DNS="" \
    IP_DNS6="" \
    SSH_PORT=2222

# Update package database and install base packages
RUN pacman -Syu --noconfirm && pacman -S --noconfirm \
    # Essential system packages
    openssh \
    ca-certificates \
    curl \
    wget \
    unzip \
    gnupg \
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
    mc \
    # File system support
    nfs-utils \
    cifs-utils \
    fuse3 \
    # Archive tools
    p7zip \
    xz \
    tar \
    # Security tools
    openssl \
    gnupg \
    pass \
    # Data processing
    jq \
    # Database clients
    postgresql \
    mysql \
    sqlite \
    redis \
    # Programming languages
    python \
    python-pip \
    # Network tools
    rsync \
    openssh \
    iproute2 \
    net-tools \
    iputils \
    # Search and processing
    ripgrep \
    fzf \
    # Configuration management
    ansible \
    # HTTP tools
    # XML processing
    # Document processing
    pandoc \
    # Additional tools
    which \
    base-devel \
    && pacman -Scc --noconfirm

# Install Go (latest stable)
RUN GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1) \
    && if [ -z "$GO_VERSION" ]; then \
        echo "Failed to get Go version from official API, installation will fail" && \
        exit 1; \
    fi \
    && echo "Installing Go version: $GO_VERSION" \
    && wget https://golang.org/dl/${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf ${GO_VERSION}.linux-amd64.tar.gz \
    && rm ${GO_VERSION}.linux-amd64.tar.gz

# Add Go to PATH
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Node.js
RUN pacman -S --noconfirm nodejs npm

# Install OpenTofu
RUN for i in 1 2 3; do \
        TOFU_VERSION=$(curl -s --fail https://api.github.com/repos/opentofu/opentofu/releases/latest | jq -r .tag_name | sed 's/v//') && break || sleep 30; \
    done \
    && if [ -z "$TOFU_VERSION" ]; then \
        echo "Failed to get OpenTofu version from API, installation will fail" && \
        exit 1; \
    fi \
    && echo "Installing OpenTofu version: $TOFU_VERSION" \
    && wget https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_amd64.zip \
    && unzip -o tofu_${TOFU_VERSION}_linux_amd64.zip \
    && mv tofu /usr/local/bin/ \
    && rm tofu_${TOFU_VERSION}_linux_amd64.zip

# Install Terraform
RUN for i in 1 2 3; do \
        TERRAFORM_VERSION=$(curl -s --fail https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r .tag_name | sed 's/v//') && break || sleep 30; \
    done \
    && if [ -z "$TERRAFORM_VERSION" ]; then \
        echo "Failed to get Terraform version from API, installation will fail" && \
        exit 1; \
    fi \
    && echo "Installing Terraform version: $TERRAFORM_VERSION" \
    && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install kubectl
RUN KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) \
    && curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install yq
RUN for i in 1 2 3; do \
        YQ_VERSION=$(curl -s --fail https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$YQ_VERSION" ]; then \
        echo "Failed to get yq version from API, installation will fail" && \
        exit 1; \
    fi \
    && echo "Installing yq version: $YQ_VERSION" \
    && wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Install k9s
RUN for i in 1 2 3; do \
        K9S_VERSION=$(curl -s --fail https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name) && break || sleep 30; \
    done \
    && if [ -z "$K9S_VERSION" ]; then \
        echo "Failed to get k9s version from API, installation will fail" && \
        exit 1; \
    fi \
    && echo "Installing k9s version: $K9S_VERSION" \
    && curl -sL https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz | tar xz -C /tmp \
    && mv /tmp/k9s /usr/local/bin/

# Install Vault
RUN for i in 1 2 3; do \
        VAULT_VERSION=$(curl -s --fail https://api.github.com/repos/hashicorp/vault/releases/latest | jq -r .tag_name | sed 's/v//') && break || sleep 30; \
    done \
    && if [ -z "$VAULT_VERSION" ]; then \
        echo "Failed to get Vault version from API, installation will fail" && \
        exit 1; \
    fi \
    && echo "Installing Vault version: $VAULT_VERSION" \
    && wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip \
    && unzip -o vault_${VAULT_VERSION}_linux_amd64.zip \
    && mv vault /usr/local/bin/ \
    && rm vault_${VAULT_VERSION}_linux_amd64.zip

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip -o awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install kubectx and kubens
RUN git clone --depth 1 https://github.com/ahmetb/kubectx /opt/kubectx \
    && ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx \
    && ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz | tar xz \
    && mv docker/docker /usr/local/bin/ \
    && rm -rf docker

# Configure SSH to use port 2222 by default
RUN mkdir /var/run/sshd \
    && ssh-keygen -A \
    && sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Install Oh My Zsh for root
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Setup shell completions and aliases
RUN echo 'source <(kubectl completion bash)' >> /root/.bashrc \
    && echo 'source <(helm completion bash)' >> /root/.bashrc \
    && echo 'complete -C aws_completer aws' >> /root/.bashrc \
    && echo '' >> /root/.bashrc \
    && echo '# Custom aliases with autocomplete' >> /root/.bashrc \
    && echo 'alias k="kubectl"' >> /root/.bashrc \
    && echo 'alias h="helm"' >> /root/.bashrc \
    && echo 'alias ot="tofu"' >> /root/.bashrc \
    && echo 'alias tf="terraform"' >> /root/.bashrc \
    && echo 'alias v="vault"' >> /root/.bashrc \
    && echo 'alias kx="kubectx"' >> /root/.bashrc \
    && echo 'alias kn="kubens"' >> /root/.bashrc \
    && echo '' >> /root/.bashrc \
    && echo 'complete -o default -F __start_kubectl k' >> /root/.bashrc \
    && echo 'complete -o default -F _helm h' >> /root/.bashrc

# Setup zsh completions and aliases
RUN echo 'autoload -U compinit && compinit' >> /root/.zshrc \
    && echo 'source <(kubectl completion zsh)' >> /root/.zshrc \
    && echo 'source <(helm completion zsh)' >> /root/.zshrc \
    && echo 'complete -C aws_completer aws' >> /root/.zshrc \
    && echo '' >> /root/.zshrc \
    && echo '# Custom aliases with autocomplete' >> /root/.zshrc \
    && echo 'alias k="kubectl"' >> /root/.zshrc \
    && echo 'alias h="helm"' >> /root/.zshrc \
    && echo 'alias ot="tofu"' >> /root/.zshrc \
    && echo 'alias tf="terraform"' >> /root/.zshrc \
    && echo 'alias v="vault"' >> /root/.zshrc \
    && echo 'alias kx="kubectx"' >> /root/.zshrc \
    && echo 'alias kn="kubens"' >> /root/.zshrc \
    && echo '' >> /root/.zshrc \
    && echo 'compdef k=kubectl' >> /root/.zshrc \
    && echo 'compdef h=helm' >> /root/.zshrc \
    && echo 'compdef ot=tofu' >> /root/.zshrc \
    && echo 'compdef tf=terraform' >> /root/.zshrc \
    && echo 'compdef v=vault' >> /root/.zshrc

# Create directories for mounted volumes
RUN mkdir -p /root/config

# Copy entrypoint script and huh command
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY huh /usr/local/bin/huh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/huh

# Clean up package cache
RUN pacman -Scc --noconfirm

# Expose SSH port 2222
EXPOSE 2222

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/usr/sbin/sshd", "-D"]"' >> /root/.bashrc \
    && echo 'alias kx="kubectx"' >> /root/.bashrc \
    && echo 'alias kn="kubens"' >> /root/.bashrc \
    && echo '' >> /root/.bashrc \
    && echo 'complete -o default -F __start_kubectl k' >> /root/.bashrc \
    && echo 'complete -o default -F _helm h' >> /root/.bashrc

# Setup zsh completions and aliases
RUN echo 'autoload -U compinit && compinit' >> /root/.zshrc \
    && echo 'source <(kubectl completion zsh)' >> /root/.zshrc \
    && echo 'source <(helm completion zsh)' >> /root/.zshrc \
    && echo 'complete -C aws_completer aws' >> /root/.zshrc \
    && echo '' >> /root/.zshrc \
    && echo '# Custom aliases with autocomplete' >> /root/.zshrc \
    && echo 'alias k="kubectl"' >> /root/.zshrc \
    && echo 'alias h="helm"' >> /root/.zshrc \
    && echo 'alias ot="tofu"' >> /root/.zshrc \
    && echo 'alias tf="terraform"' >> /root/.zshrc \
    && echo 'alias v="vault"' >> /root/.zshrc \
    && echo 'alias kx="kubectx"' >> /root/.zshrc \
    && echo 'alias kn="kubens"' >> /root/.zshrc \
    && echo '' >> /root/.zshrc \
    && echo 'compdef k=kubectl' >> /root/.zshrc \
    && echo 'compdef h=helm' >> /root/.zshrc \
    && echo 'compdef ot=tofu' >> /root/.zshrc \
    && echo 'compdef tf=terraform' >> /root/.zshrc \
    && echo 'compdef v=vault' >> /root/.zshrc

# Create directories for mounted volumes
RUN mkdir -p /root/config

# Copy entrypoint script and huh command
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY huh /usr/local/bin/huh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/huh

# Clean up package cache
RUN pacman -Scc --noconfirm

# Expose SSH port
EXPOSE 22

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/usr/sbin/sshd", "-D"]