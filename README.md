# MagicShell - Universal Infrastructure Management Container

🎭 A comprehensive Ubuntu 24.04 LTS server minimal development container with pre-installed tools for DevOps, Kubernetes, and system administration.

**Repository**: https://github.com/EricZarnosky/MagicShell

## Features

### Base Image Optimization
- **Ubuntu 24.04 LTS Server Minimal**: Optimized base image for reduced container size
- **Multi-architecture Support**: Built for both AMD64 and ARM64 platforms
- **Fixed Tool Versions**: Uses specific versions to avoid GitHub API rate limits during builds
- **Layer Optimization**: Minimized layers and cleaned up package caches for smaller image size

### Installed Tools
- **System Tools**: openssh, git, nano, vim, neovim, tmux, screen, mc, rsync, fzf, ripgrep
- **Shells**: bash (with completion), zsh (with Oh My Zsh and completions)
- **DevOps Tools**: opentofu, terraform, kubectl, helm, kustomize, k9s, ansible, packer, pulumi
- **Kubernetes**: talosctl, kubectx, kubens, flux, argocd, skaffold
- **Container Tools**: docker-cli, nerdctl, crictl, containerd
- **Programming Languages**: Python 3 (with pip), Go, Node.js (with npm, for JavaScript)
- **Cloud CLI Tools**: 
  - **AWS**: aws-cli v2
  - **Azure**: az-cli  
  - **Google Cloud**: gcloud
  - **DigitalOcean**: doctl
  - **Multi-cloud**: PowerShell
- **Data Processing**: jq, yq, xq, hcl2json, htmlq, dasel, httpie, xmlstarlet, pandoc
- **Database CLI Tools**: 
  - **SQL**: postgresql-client, mysql-client, sqlite3
  - **NoSQL**: mongosh, mongodb-database-tools, redis-tools, cqlsh (Cassandra), etcdctl
  - **Search**: elasticsearch-cli
- **Security & Secrets**: sops, openbao, vault, pass, gpg
- **Monitoring**: promtool (Prometheus)
- **CI/CD**: jenkins-cli, flux, argocd, skaffold
- **File Systems**: NFS and SMB/CIFS support
- **Package Management**: nix
- **Utilities**: 7zip, openssl, curl, wget, huh (version info tool)
- **Networking**: tailscale for VPN connectivity

### Persistent Storage
- Root home directory (`/root`) mapped to `./config` for persistence
- Configuration files automatically symlinked from persistent storage
- SSH host keys preserved across container restarts
- Kubernetes configurations, Git settings, and shell customizations persist

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/EricZarnosky/MagicShell.git
   cd MagicShell
   ```

2. **Create the config directory**:
   ```bash
   mkdir -p config secrets
   ```

3. **Set up environment** (optional):
   ```bash
   cp .env.example .env
   # Edit .env with your preferences
   ```

4. **Build and run**:
   ```bash
   docker-compose up -d
   ```

5. **Connect via SSH**:
   ```bash
   ssh root@localhost -p 2222
   # Default password: "password" (change this!)
   ```

## Using Pre-built Image

Instead of building locally, you can use the pre-built image:

```bash
# Pull the latest image
docker pull ghcr.io/ericzarnosky/magicshell:latest

# Update docker-compose.yml to use pre-built image
# Comment out 'build: .' and use:
# image: ghcr.io/ericzarnosky/magicshell:latest
```

## Docker Run Command

For quick CLI usage without docker-compose:

```bash
# Basic usage (bash shell, default password)
docker run -d --name magicshell --privileged --network host -p 2222:22 -e PASSWORD=mypassword -v ./config:/root/config ghcr.io/ericzarnosky/magicshell:latest

# With custom shell and hostname
docker run -d --name magicshell --privileged --network host -p 2222:22 -e PASSWORD=mypassword -e SHELL=zsh -e HOSTNAME=MyContainer -v ./config:/root/config ghcr.io/ericzarnosky/magicshell:latest

# Full command with all options
docker run -d \
  --name magicshell \
  --hostname MagicShell \
  --restart unless-stopped \
  --privileged \
  --network host \
  -p 2222:22 \
  -e PASSWORD=your_secure_password \
  -e SHELL=bash \
  -e HOSTNAME=MagicShell \
  -e TZ=UTC \
  -e PUID=1000 \
  -e PGID=1000 \
  -e ENABLE_TAILSCALE=false \
  -v $(pwd)/config:/root/config \
  -v $(pwd)/config/fstab:/etc/fstab:ro \
  --cap-add SYS_ADMIN \
  --cap-add NET_ADMIN \
  --cap-add DAC_READ_SEARCH \
  --device /dev/fuse \
  ghcr.io/ericzarnosky/magicshell:latest
```

## Configuration

### Password Management

You can set the root password in two ways:

**Method 1: Environment Variable**
```yaml
environment:
  - PASSWORD=your_secure_password
  - SHELL=bash  # Options: bash, zsh, sh
  - HOSTNAME=MagicShell  # Container hostname
  - PUID=1000   # User ID for file permissions
  - PGID=1000   # Group ID for file permissions
```

**Method 2: Password File (Recommended for production)**
```yaml
environment:
  - PASSWORD_FILE=/run/secrets/root_password
  - SHELL=zsh  # Set your preferred shell
  - HOSTNAME=MyContainer
secrets:
  - root_password

secrets:
  root_password:
    file: ./secrets/root_password.txt
```

### Shell Configuration

You can set the default shell for the root user using the `SHELL` environment variable:

- `SHELL=bash` (default) - Use Bash shell
- `SHELL=zsh` - Use Zsh with Oh My Zsh
- `SHELL=sh` - Use basic sh shell

### Hostname Configuration

Set the container hostname using the `HOSTNAME` environment variable:

- `HOSTNAME=MagicShell` (default) - Default hostname
- `HOSTNAME=MyContainer` - Custom hostname

### User Permissions

You can set the user and group IDs for file ownership using the `PUID` and `PGID` environment variables:

- `PUID=1000` - User ID (default: 0 for root)
- `PGID=1000` - Group ID (default: 0 for root)

This is useful when mounting volumes to ensure files have the correct ownership on the host system:

```bash
# Get your user ID and group ID
id
# uid=1000(username) gid=1000(username)

# Set in docker-compose.yml
environment:
  - PUID=1000
  - PGID=1000
```

The shell setting affects:
- Default login shell for SSH connections
- Shell used in `docker exec` when not specified
- Shell completions and configurations loaded

### Persistent Configuration Files

The following files/directories are automatically managed in persistent storage:

- `.bashrc` - Bash configuration
- `.zshrc` - Zsh configuration  
- `.vimrc` - Vim configuration
- `.tmux.conf` - Tmux configuration
- `.kube/` - Kubernetes configurations
- `.ssh/` - SSH keys and configuration
- `.gitconfig` - Git configuration
- `.terraformrc` - Terraform configuration
- `.helm/` - Helm configuration
- `tailscale-state/` - Tailscale authentication state

### File System Mounts

Place your fstab configuration in `./config/fstab` to automatically mount NFS/SMB shares:

```bash
# Example fstab entries
192.168.1.100:/mnt/nfs /mnt/nfs nfs defaults 0 0
//192.168.1.100/share /mnt/smb cifs username=user,password=pass 0 0
```

### Tailscale Integration

To enable Tailscale:

1. Set `ENABLE_TAILSCALE=true` in your environment
2. After first run, authenticate: `docker exec -it magicshell tailscale up`
3. Authentication state persists in `./config/tailscale-state/`

## Aliases and Shortcuts

The container includes convenient aliases for commonly used tools with full autocomplete support:

### Available Aliases
| Alias | Command | Description |
|-------|---------|-------------|
| `k` | `kubectl` | Kubernetes CLI |
| `kx` | `kubectx` | Switch between Kubernetes contexts |
| `kn` | `kubens` | Switch between Kubernetes namespaces |
| `t` | `talosctl` | Talos Linux CLI |
| `h` | `helm` | Helm package manager |
| `kz` | `kustomize` | Kubernetes configuration customization |
| `fcd` | `flux` | Flux GitOps toolkit |
| `acd` | `argocd` | ArgoCD CLI |
| `ot` | `tofu` | OpenTofu (Terraform alternative) |
| `tf` | `terraform` | Terraform |
| `v` | `vault` | HashiCorp Vault |

### Autocomplete Support
All aliases include full autocomplete support in both Bash and Zsh:
- **Bash**: Uses `complete` functions to map alias completions to original commands
- **Zsh**: Uses `compdef` to associate alias completions with original commands

### Usage Examples
```bash
# These commands are equivalent and both have autocomplete:
kubectl get pods
k get pods

# Context and namespace switching with autocomplete
kubectx production
kx production  # Shows available contexts with tab completion

kubens kube-system  
kn kube-system  # Shows available namespaces with tab completion

# Helm with autocomplete
helm install my-app ./chart
h install my-app ./chart

# Terraform/OpenTofu with autocomplete
terraform plan
tf plan
tofu plan
ot plan

# Vault operations
vault status
v status
```

### SSH Access
```bash
ssh root@localhost -p 2222
```

### Execute Commands
```bash
docker exec -it magicshell bash
docker exec -it magicshell zsh
```

### Tool Version Information
```bash
# Show all installed tool versions
docker exec -it magicshell huh

# Show detailed information about a specific tool
docker exec -it magicshell huh --app kubectl
docker exec -it magicshell huh --app opentofu
docker exec -it magicshell huh -a python3

# Show help for huh command
docker exec -it magicshell huh --help
```

### Programming and Scripting
```bash
# Python development
docker exec -it magicshell python3 --version
docker exec -it magicshell pip3 list

# Go development  
docker exec -it magicshell go version
docker exec -it magicshell go env

# Node.js development
docker exec -it magicshell node --version
docker exec -it magicshell npm --version

# PowerShell
docker exec -it magicshell pwsh
```

### Cloud Operations
```bash
# AWS CLI
docker exec -it magicshell aws configure
docker exec -it magicshell aws s3 ls

# Azure CLI
docker exec -it magicshell az login
docker exec -it magicshell az account list

# Google Cloud CLI
docker exec -it magicshell gcloud auth login
docker exec -it magicshell gcloud projects list

# DigitalOcean CLI
docker exec -it magicshell doctl auth init
docker exec -it magicshell doctl compute droplet list

# Ansible
docker exec -it magicshell ansible --version
docker exec -it magicshell ansible-playbook playbook.yml
```

### Container & Kubernetes Operations
```bash
# Docker (remote)
docker exec -it magicshell docker -H tcp://remote-host:2376 ps

# Kubernetes context switching
docker exec -it magicshell kubectx production
docker exec -it magicshell kx staging  # Using alias
docker exec -it magicshell kubens kube-system
docker exec -it magicshell kn default  # Using alias

# Kubernetes tools with aliases
docker exec -it magicshell kubectl get nodes
docker exec -it magicshell k get pods  # Using alias
docker exec -it magicshell k9s
docker exec -it magicshell flux get sources git
docker exec -it magicshell fcd get sources git  # Using alias

# Container runtime tools
docker exec -it magicshell crictl ps
docker exec -it magicshell nerdctl ps

# Helm operations
docker exec -it magicshell helm list
docker exec -it magicshell h install myapp ./chart  # Using alias

# Talos Linux
docker exec -it magicshell talosctl config endpoint 10.0.0.1
docker exec -it magicshell t version  # Using alias

# Kustomize
docker exec -it magicshell kustomize build .
docker exec -it magicshell kz build .  # Using alias

# ArgoCD
docker exec -it magicshell argocd app list
docker exec -it magicshell acd app sync myapp  # Using alias
```

### Infrastructure as Code
```bash
# OpenTofu (Terraform alternative)
docker exec -it magicshell tofu init
docker exec -it magicshell tofu plan
docker exec -it magicshell tofu apply
docker exec -it magicshell ot version  # Using alias

# Terraform
docker exec -it magicshell terraform init
docker exec -it magicshell terraform plan
docker exec -it magicshell terraform apply
docker exec -it magicshell tf version  # Using alias

# Pulumi
docker exec -it magicshell pulumi up

# Packer
docker exec -it magicshell packer build template.json
```

### Security & Secrets Management
```bash
# OpenBao (Vault alternative)
docker exec -it magicshell bao server -dev
docker exec -it magicshell bao login
docker exec -it magicshell bao kv put secret/myapp password=secret

# HashiCorp Vault
docker exec -it magicshell vault server -dev
docker exec -it magicshell vault login
docker exec -it magicshell vault kv put secret/myapp password=secret
docker exec -it magicshell v status  # Using alias

# SOPS (encrypted files)
docker exec -it magicshell sops -e secrets.yaml

# Password manager
docker exec -it magicshell pass show myservice/password

# GPG operations
docker exec -it magicshell gpg --gen-key
```

### Database Operations
```bash
# PostgreSQL
docker exec -it magicshell psql -h hostname -U username -d database

# MySQL
docker exec -it magicshell mysql -h hostname -u username -p

# MongoDB
docker exec -it magicshell mongosh mongodb://hostname:27017

# Redis
docker exec -it magicshell redis-cli -h hostname

# Cassandra
docker exec -it magicshell cqlsh hostname

# SQLite
docker exec -it magicshell sqlite3 database.db
```

### Data Processing & APIs
```bash
# JSON processing
docker exec -it magicshell echo '{"name":"test"}' | jq '.name'

# YAML processing  
docker exec -it magicshell yq '.spec.containers[0].name' pod.yaml

# XML processing
docker exec -it magicshell echo '<root><n>test</n></root>' | xq '.root.name'
docker exec -it magicshell xmlstarlet sel -t -v "//name" file.xml

# HCL processing (OpenTofu/Terraform files)
docker exec -it magicshell hcl2json main.tf | jq '.resource'

# HTML processing
docker exec -it magicshell htmlq 'title' index.html

# Universal data processing (JSON, YAML, TOML, XML, CSV)
docker exec -it magicshell dasel -f data.yaml '.items.[0].name'

# Markdown processing
docker exec -it magicshell pandoc README.md -o README.html

# HTTP requests
docker exec -it magicshell http GET api.example.com/users
docker exec -it magicshell curl -X POST api.example.com/data

# File searching
docker exec -it magicshell rg "pattern" /path/to/search
docker exec -it magicshell fzf
```

### File Operations
```bash
# Access Midnight Commander
docker exec -it magicshell mc

# File compression/extraction
docker exec -it magicshell 7z x archive.7z
```

## Directory Structure

```
MagicShell/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── huh
├── .dockerignore
├── .env.example
├── README.md
├── .github/
│   └── workflows/
│       └── docker-build.yml
├── config/              # Persistent home directory
│   ├── .bashrc
│   ├── .zshrc
│   ├── .kube/
│   ├── .ssh/
│   ├── fstab
│   └── tailscale-state/
└── secrets/            # Password files (if using)
    └── root_password.txt
```

## Automated Builds

The container is automatically built and published to GitHub Container Registry with optimized multi-platform builds:

- **Latest builds**: `ghcr.io/ericzarnosky/magicshell:latest`
- **Date-tagged builds**: `ghcr.io/ericzarnosky/magicshell:YYYY.MM.DD-<commit>`
- **Version tags**: `ghcr.io/ericzarnosky/magicshell:v1.0.0` (when you tag releases)

### Build Optimizations
- **Multi-platform builds**: Supports both AMD64 and ARM64 architectures
- **Parallel builds**: Uses matrix strategy for faster build times
- **Latest tool versions**: Automatically installs current releases with retry logic for reliability
- **Optimized caching**: Uses GitHub Actions cache for faster subsequent builds
- **Smart fallbacks**: Uses known-good versions if GitHub API calls fail

### Available Tags
- `:latest` - Latest build from main branch
- `:main` - Latest main branch build
- `:YYYY.MM.DD-<commit>` - Date and commit specific builds
- `:v<version>` - Semantic version tags (when you create releases)

## Security Considerations

1. **Change the default password** immediately
2. **Use password files** instead of environment variables for production
3. **Secure SSH keys** in the persistent `.ssh` directory
4. **Network access** - Container runs in host network mode for Tailscale compatibility
5. **Privileged mode** - Required for NFS/SMB mounting and Tailscale

## Tool Versions (Latest with Reliability)

All tools automatically install the latest versions with intelligent retry logic to handle GitHub API rate limits:

### Version Management Strategy
- **Latest Versions**: Always installs the most current release of each tool
- **Retry Logic**: GitHub API calls retry 3 times with 30-second delays to handle rate limits
- **Fallback Versions**: If API calls fail, uses recent known-good versions as fallbacks
- **Multi-Architecture**: Automatically detects and installs correct binaries for AMD64 and ARM64

### Core Tools (Always Latest)
- **Kustomize**: Latest release (fallback: v5.5.0)
- **Go**: Latest stable (fallback: go1.23.4)
- **Node.js**: Latest LTS (fallback: v20)
- **yq**: Latest release (fallback: v4.44.3)
- **Flux**: Latest release (fallback: v2.4.0)
- **ArgoCD**: Latest release (fallback: v2.13.1)
- **Pulumi**: Latest release (fallback: v3.140.0)
- **k9s**: Latest release (fallback: v0.32.7)
- **Talosctl**: Latest release (fallback: v1.8.3)
- **And many more...**

### Benefits
- **Latest Features**: Always get the newest capabilities and improvements
- **Security Updates**: Automatic inclusion of latest security patches
- **Build Reliability**: Retry logic prevents GitHub API rate limit failures
- **No Maintenance**: No need to manually update version numbers in Dockerfile

To see all installed versions in your running container:
```bash
docker exec -it magicshell huh
```

## Troubleshooting

### Build Issues
- **GitHub API Rate Limits**: Retry logic with fallback versions prevents this issue
- **Multi-platform Support**: ARM64 builds may take longer but are fully supported
- **Network Issues**: Ensure Docker daemon has internet access during build
- **API Failures**: Builds will use fallback versions if GitHub API is unavailable

### SSH Connection Issues
- Verify port mapping: `docker-compose ps`
- Check SSH service: `docker exec -it magicshell systemctl status ssh`
- Review logs: `docker-compose logs magicshell`

### Mount Issues
- Ensure proper privileges and capabilities are set
- Check fstab syntax in `./config/fstab`
- Verify network connectivity to NFS/SMB servers

### Tailscale Issues
- Check daemon status: `docker exec -it magicshell tailscale status`
- Re-authenticate: `docker exec -it magicshell tailscale up`
- Check logs: `docker exec -it magicshell journalctl -u tailscaled`

### Tool Version Issues
- Run `docker exec -it magicshell huh` to see all installed versions
- Use `docker exec -it magicshell huh --app <tool>` for detailed tool information
- Check if tool is in PATH: `docker exec -it magicshell which <tool>`

### Shell Issues
- Check current shell: `docker exec -it magicshell echo $SHELL`
- Verify shell setting: `docker exec -it magicshell getent passwd root`
- Override temporarily: `docker exec -it magicshell zsh` or `docker exec -it magicshell bash`

### Hostname Issues
- Check current hostname: `docker exec -it magicshell hostname`
- Verify hostname setting: `docker exec -it magicshell cat /etc/hostname`

## Customization

### Adding More Tools
Edit the Dockerfile to install additional packages:

```dockerfile
RUN apt-get update && apt-get install -y \
    your-additional-package \
    && rm -rf /var/lib/apt/lists/*
```

### Shell Customization
- Bash: Edit `./config/.bashrc`
- Zsh: Edit `./config/.zshrc`
- Oh My Zsh themes and plugins can be configured in `.zshrc`

### MOTD Customization
The custom MOTD is generated automatically. To customize it, modify the `setup_motd()` function in `entrypoint.sh`.

### Port Changes
Modify the ports section in docker-compose.yml:

```yaml
ports:
  - "your_port:22"
```

## Advanced Usage

### Docker-in-Docker
Uncomment the Docker socket mount in docker-compose.yml:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

### Multiple Environments
Create separate docker-compose files:

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Shell Selection Examples

**Default Bash:**
```bash
docker run -d --name magicshell-bash -e SHELL=bash -e PASSWORD=test123 -v ./config:/root/config ghcr.io/ericzarnosky/magicshell:latest
```

**Zsh with Oh My Zsh:**
```bash
docker run -d --name magicshell-zsh -e SHELL=zsh -e PASSWORD=test123 -v ./config:/root/config ghcr.io/ericzarnosky/magicshell:latest
```

**Custom Hostname:**
```bash
docker run -d --name magicshell-custom -e HOSTNAME=DevContainer -e PASSWORD=test123 -v ./config:/root/config ghcr.io/ericzarnosky/magicshell:latest
```

### Using with CI/CD
The container can be used in CI/CD pipelines:

```yaml
# GitHub Actions example
jobs:
  deploy:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/ericzarnosky/magicshell:latest
      env:
        SHELL: bash
        HOSTNAME: CI-Runner
    steps:
      - uses: actions/checkout@v4
      - name: Deploy with kubectl
        run: kubectl apply -f manifests/
```

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `PASSWORD` | `password` | Root user password |
| `PASSWORD_FILE` | - | Path to file containing password |
| `SHELL` | `bash` | Default shell (bash, zsh, sh) |
| `HOSTNAME` | `MagicShell` | Container hostname |
| `PUID` | `0` | User ID for file permissions |
| `PGID` | `0` | Group ID for file permissions |
| `TZ` | `UTC` | Timezone |
| `ENABLE_TAILSCALE` | `false` | Enable Tailscale daemon |

## Open Source Tools

MagicShell includes both open source alternatives and original tools for maximum compatibility:

### Infrastructure as Code
- **OpenTofu** - Open source Terraform alternative (license-free)
- **Terraform** - Original HashiCorp Terraform (both tools coexist)
- Both tools can be used side-by-side with separate state files

### Secrets Management  
- **OpenBao** - Open source Vault alternative
- **HashiCorp Vault** - Original Vault (both tools coexist)
- Both tools can run simultaneously on different ports

### Compatibility
- **Coexistence**: Tools are installed to separate binaries and can run together
- **Command Compatibility**: Both tool pairs use similar command structures
- **Migration**: Easy to migrate between tools or use both as needed
- **Aliases**: Convenient shortcuts available for all tools

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the build locally: `docker-compose build`
5. Submit a pull request

## License

This project is open source. See the repository for license details.

## Support

For issues and questions:
- Create an issue on GitHub: https://github.com/EricZarnosky/MagicShell/issues
- Check existing discussions and documentation

---

**🎭 MagicShell** - Your universal infrastructure management toolkit in a container! ✨