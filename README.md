# MagicShell - Universal Infrastructure Management Container

🎭 A comprehensive Arch Linux development container with pre-installed tools for DevOps, Kubernetes, and system administration.

**Repository**: https://github.com/EricZarnosky/MagicShell

## Features

### Base Image Optimization
- **Arch Linux Rolling Release**: Always up-to-date packages and latest features
- **AMD64 Platform**: Optimized for x86_64 architecture 
- **Minimal Base**: Efficient resource usage and faster startup times
- **Layer Optimization**: Minimized layers and cleaned package caches

### Network Configuration
- **Custom MAC Address**: Set container MAC address for DHCP reservations
- **Static IP Support**: Configure static IPv4/IPv6 addresses with validation
- **Flexible DNS**: Support for multiple DNS servers with various input formats
- **DHCP Fallback**: Automatic fallback to DHCP if static configuration fails
- **Network Validation**: Comprehensive IP address and format validation

### Installed Tools
- **System Tools**: openssh, git, nano, vim, neovim, tmux, screen, mc, rsync, fzf, ripgrep
- **Shells**: bash (with completion), zsh (with Oh My Zsh and completions)
- **DevOps Tools**: opentofu, terraform, kubectl, helm, k9s, ansible
- **Kubernetes**: kubectx, kubens
- **Container Tools**: docker-cli
- **Programming Languages**: Python 3 (with pip), Go, Node.js (with npm)
- **Cloud CLI Tools**: 
  - **AWS**: aws-cli v2
- **Data Processing**: jq, yq
- **Security & Secrets**: vault, pass, gpg
- **File Systems**: NFS and SMB/CIFS support
- **Network Tools**: iproute2, net-tools, iputils
- **Utilities**: 7zip, openssl, curl, wget, huh (version info tool)

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

## Network Configuration

### MAC Address Configuration

Set a custom MAC address for DHCP reservations:

```bash
# Supported formats:
MAC=0123456789AB           # 12 hex digits
MAC=01 23 45 67 89 AB      # Space separated
MAC=01-23-45-67-89-AB      # Dash separated  
MAC=01:23:45:67:89:AB      # Colon separated (default format)
```

**Default MAC**: `0D:EC:AF:C0:FF:EE`

### DHCP Configuration (Default)

Leave IP settings empty for automatic DHCP:

```bash
# .env file
MAC=0D:EC:AF:C0:FF:EE
# All IP variables empty = DHCP mode
```

### Static IP Configuration

Configure static networking by setting IP_ADDRESS:

```bash
# Basic static IPv4
IP_ADDRESS=192.168.1.100/24
IP_GATEWAY=192.168.1.1
IP_DNS=8.8.8.8,8.8.4.4

# Full static configuration with IPv6
IP_ADDRESS=192.168.1.100/24
IP_ADDRESS6=2001:db8::100/64
IP_GATEWAY=192.168.1.1
IP_GATEWAY6=2001:db8::1
IP_DNS=8.8.8.8, 8.8.4.4
IP_DNS6=2001:4860:4860::8888,2001:4860:4860::8844
```

### DNS Configuration Formats

DNS servers support flexible input formats:

```bash
# Comma separated
IP_DNS=8.8.8.8,8.8.4.4

# Space separated  
IP_DNS=8.8.8.8 8.8.4.4

## MagicShell - Universal Infrastructure Management Container

🎭 A comprehensive Arch Linux development container with pre-installed tools for DevOps, Kubernetes, and system administration.

**Repository**: https://github.com/EricZarnosky/MagicShell

## Features

### Base Image Optimization
- **Arch Linux Rolling Release**: Always up-to-date packages and latest features
- **AMD64 Platform**: Optimized for x86_64 architecture 
- **Minimal Base**: Efficient resource usage and faster startup times
- **Layer Optimization**: Minimized layers and cleaned package caches

### Installed Tools
- **System Tools**: openssh, git, nano, vim, neovim, tmux, screen, mc, rsync, fzf, ripgrep
- **Shells**: bash (with completion), zsh (with Oh My Zsh and completions)
- **DevOps Tools**: opentofu, terraform, kubectl, helm, k9s, ansible
- **Kubernetes**: kubectx, kubens
- **Container Tools**: docker-cli
- **Programming Languages**: Python 3 (with pip), Go, Node.js (with npm)
- **Cloud CLI Tools**: 
  - **AWS**: aws-cli v2
- **Data Processing**: jq, yq
- **Security & Secrets**: vault, pass, gpg
- **File Systems**: NFS and SMB/CIFS support
- **Utilities**: 7zip, openssl, curl, wget, huh (version info tool)

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

### SSH Port Configuration

The SSH port is configurable and defaults to 2222 during container installation:

```bash
# Set custom SSH port
SSH_PORT=2200

# Container will configure SSH daemon to use this port internally
# Port mapping will be: host_port:container_port (2200:2200)
```

**Default SSH Port**: `2222` (set in container during build)

### Connection Examples

```bash
# Default port (2222)
ssh root@localhost -p 2222

# Custom port (if SSH_PORT=2200)
ssh root@localhost -p 2200

# With static IP
ssh root@192.168.1.100 -p 2222
```

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

## Aliases and Shortcuts

The container includes convenient aliases for commonly used tools with full autocomplete support:

### Available Aliases
| Alias | Command | Description |
|-------|---------|-------------|
| `k` | `kubectl` | Kubernetes CLI |
| `kx` | `kubectx` | Switch between Kubernetes contexts |
| `kn` | `kubens` | Switch between Kubernetes namespaces |
| `h` | `helm` | Helm package manager |
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

## Usage Examples

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
```

### Cloud Operations
```bash
# AWS CLI
docker exec -it magicshell aws configure
docker exec -it magicshell aws s3 ls

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

# Helm operations
docker exec -it magicshell helm list
docker exec -it magicshell h install myapp ./chart  # Using alias

# kubectx and kubens have built-in completion support
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
```

### Security & Secrets Management
```bash
# HashiCorp Vault
docker exec -it magicshell vault server -dev
docker exec -it magicshell vault login
docker exec -it magicshell vault kv put secret/myapp password=secret
docker exec -it magicshell v status  # Using alias

# Password manager
docker exec -it magicshell pass show myservice/password

# GPG operations
docker exec -it magicshell gpg --gen-key
```

### Data Processing & APIs
```bash
# JSON processing
docker exec -it magicshell echo '{"name":"test"}' | jq '.name'

# YAML processing  
docker exec -it magicshell yq '.spec.containers[0].name' pod.yaml

# HTTP requests
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
├── Dockerfile                   # Arch Linux container definition
├── docker-compose.yml          # Container orchestration
├── entrypoint.sh               # Container startup script
├── huh                         # Tool version display script
├── .dockerignore              # Docker build exclusions
├── .env.example               # Environment template
├── README.md                  # This file
├── .github/
│   └── workflows/
│       └── docker-build.yml   # Automated build pipeline
├── config/                    # Persistent home directory
│   ├── .bashrc
│   ├── .zshrc
│   ├── .kube/
│   ├── .ssh/
│   ├── fstab
│   └── tailscale-state/
└── secrets/                   # Password files (if using)
    └── root_password.txt
```

## Automated Builds

The container is automatically built and published to GitHub Container Registry:

- **Latest builds**: `ghcr.io/ericzarnosky/magicshell:latest`
- **Date-tagged builds**: `ghcr.io/ericzarnosky/magicshell:2025.06.28-<commit>`
- **Version tags**: `ghcr.io/ericzarnosky/magicshell:0.0.1` (when you tag releases)

### Build Optimizations
- **AMD64 platform**: Single architecture for maximum compatibility
- **Latest tool versions**: Automatically installs current releases with retry logic
- **Optimized caching**: Uses GitHub Actions cache for faster builds
- **Smart fallbacks**: Uses known-good approaches if downloads fail

### Available Tags
- `:latest` - Latest build from main branch
- `:0.0.1`, `:0.0`, `:0` - Semantic version tags
- `:YYYY.MM.DD-<commit>` - Date and commit specific builds

## Security Considerations

1. **Change the default password** immediately
2. **Use password files** instead of environment variables for production
3. **Secure SSH keys** in the persistent `.ssh` directory
4. **Network access** - Container runs in host network mode for optimal performance
5. **Privileged mode** - Required for NFS/SMB mounting capabilities

## Tool Versions (Latest with Reliability)

All tools automatically install the latest versions with intelligent retry logic:

### Version Management Strategy
- **Latest Versions**: Always installs the most current release of each tool
- **Retry Logic**: GitHub API calls retry 3 times with 30-second delays
- **Multi-Architecture**: AMD64 optimized for maximum compatibility
- **Pacman Integration**: Uses Arch package manager where possible for efficiency

### Core Tools (Always Latest)
- **Go**: Latest stable from official source
- **Node.js**: Latest LTS from Arch repos
- **OpenTofu**: Latest release from GitHub
- **Terraform**: Latest release from HashiCorp
- **kubectl**: Latest stable from Kubernetes
- **Helm**: Latest via official installer
- **yq**: Latest release from GitHub
- **k9s**: Latest release from GitHub
- **Vault**: Latest release from HashiCorp
- **AWS CLI**: Latest v2 from Amazon

### Benefits
- **Latest Features**: Always get the newest capabilities and improvements
- **Security Updates**: Automatic inclusion of latest security patches
- **Build Reliability**: Retry logic prevents temporary download failures
- **No Maintenance**: No need to manually update version numbers

To see all installed versions in your running container:
```bash
docker exec -it magicshell huh
```

## Troubleshooting

### Build Issues
- **GitHub API Rate Limits**: Retry logic with delays prevents this issue
- **Network Issues**: Ensure Docker daemon has internet access during build
- **Pacman Updates**: Arch rolling release may occasionally have package conflicts

### SSH Connection Issues
- Verify port mapping: `docker-compose ps`
- Check SSH service: `docker exec -it magicshell systemctl status sshd`
- Review logs: `docker-compose logs magicshell`

### Mount Issues
- Ensure proper privileges and capabilities are set
- Check fstab syntax in `./config/fstab`
- Verify network connectivity to NFS/SMB servers

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
RUN pacman -S --noconfirm \
    your-additional-package \
    && pacman -Scc --noconfirm
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

## Arch Linux Benefits

### Why Arch Linux?
- **Rolling Release**: Always latest packages and features
- **Pacman Package Manager**: Fast, efficient, and reliable
- **Minimal Base**: Smaller attack surface and faster startup
- **AUR Access**: Largest package repository in Linux
- **Cutting Edge**: Latest kernels, tools, and libraries
- **Customization**: Build exactly what you need

### Performance Advantages
- **Smaller Base Image**: Faster downloads and startup
- **Optimized Packages**: Compiled for modern x86_64 with optimizations
- **Less Bloat**: Only essential components included
- **Faster Package Operations**: Pacman is extremely efficient

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the build locally: `docker-compose build`
5. Submit a pull request

## Versioning

This project uses semantic versioning:
- **Major**: Breaking changes or significant architecture updates
- **Minor**: New tools or features added
- **Patch**: Bug fixes, security updates, or tool version bumps

To create a new release:
```bash
git tag v0.1.0
git push origin v0.1.0
```

## License

This project is open source. See the repository for license details.

## Support

For issues and questions:
- Create an issue on GitHub: https://github.com/EricZarnosky/MagicShell/issues
- Check existing discussions and documentation

---

**🎭 MagicShell** - Your universal infrastructure management toolkit in a container! ✨