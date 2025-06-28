#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' | tr '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::$'
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0 
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' | tr '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::$'
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0 
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0 ]] && echo "IPv6 DNS: ${dns6_servers[*]}"
    
    # Apply network configuration
    local interface="eth0"
    
    # Configure IPv4
    echo "Configuring IPv4 address: $IP_ADDRESS on $interface"
    ip addr add "$IP_ADDRESS" dev "$interface" || echo "Warning: Failed to set IPv4 address"
    ip link set "$interface" up
    
    # Configure IPv4 gateway
    if [[ -n "$IP_GATEWAY" ]]; then
        echo "Setting IPv4 gateway: $IP_GATEWAY"
        ip route add default via "$IP_GATEWAY" || echo "Warning: Failed to set IPv4 gateway"
    fi
    
    # Configure IPv6
    if [[ -n "$IP_ADDRESS6" ]]; then
        echo "Configuring IPv6 address: $IP_ADDRESS6 on $interface"
        ip -6 addr add "$IP_ADDRESS6" dev "$interface" || echo "Warning: Failed to set IPv6 address"
    fi
    
    # Configure IPv6 gateway
    if [[ -n "$IP_GATEWAY6" ]]; then
        echo "Setting IPv6 gateway: $IP_GATEWAY6"
        ip -6 route add default via "$IP_GATEWAY6" || echo "Warning: Failed to set IPv6 gateway"
    fi
    
    # Configure DNS
    if [[ ${#dns4_servers[@]} -gt 0 ]] || [[ ${#dns6_servers[@]} -gt 0 ]]; then
        echo "Configuring DNS servers..."
        echo "# Generated by MagicShell" > /etc/resolv.conf
        for dns in "${dns4_servers[@]}" "${dns6_servers[@]}"; do
            echo "nameserver $dns" >> /etc/resolv.conf
        done
    fi
    
    return 0
}

# Function to setup hostname
setup_hostname() {
    local target_hostname="${HOSTNAME:-MagicShell}"
    echo "Setting hostname to: $target_hostname"
    echo "$target_hostname" > /etc/hostname
    hostname "$target_hostname"
    
    # Update /etc/hosts
    echo "127.0.0.1 localhost $target_hostname" > /etc/hosts
    echo "::1 localhost ip6-localhost ip6-loopback $target_hostname" >> /etc/hosts
}

# Function to setup custom MOTD
setup_motd() {
    cat > /etc/motd << 'EOF'

███╗   ███╗ █████╗  ██████╗ ██╗ ██████╗███████╗██╗  ██╗███████╗██╗     ██╗     
████╗ ████║██╔══██╗██╔════╝ ██║██╔════╝██╔════╝██║  ██║██╔════╝██║     ██║     
██╔████╔██║███████║██║  ███╗██║██║     ███████╗███████║█████╗  ██║     ██║     
██║╚██╔╝██║██╔══██║██║   ██║██║██║     ╚════██║██╔══██║██╔══╝  ██║     ██║     
██║ ╚═╝ ██║██║  ██║╚██████╔╝██║╚██████╗███████║██║  ██║███████╗███████╗███████╗
╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝

🎭 MagicShell - Universal Infrastructure Management Container

📊 Tool Versions:    Run 'huh' to see all installed tools and versions
🔍 Tool Details:     Run 'huh --app <tool>' for detailed information  
📦 Repository:       https://github.com/EricZarnosky/MagicShell
🏗️  Build Info:      Check environment variables BUILD_DATE and VCS_REF

🚀 Quick Start:
   • List tools:      huh
   • Cloud login:     aws configure
   • Kubernetes:      kubectl get nodes, k9s
   • Infrastructure:  tofu plan, terraform apply
   • Secrets:         vault server -dev

EOF

    # Add build info if available
    if [ -n "$BUILD_DATE" ]; then
        echo "🕐 Build Date:       $BUILD_DATE" >> /etc/motd
    fi
    if [ -n "$VCS_REF" ]; then
        echo "📝 Git Commit:       $VCS_REF" >> /etc/motd
    fi
    
    # Add network info
    local normalized_mac
    if normalized_mac=$(normalize_mac "$MAC"); then
        echo "🌐 MAC Address:      $normalized_mac" >> /etc/motd
    fi
    
    if [[ -n "$IP_ADDRESS" ]]; then
        echo "🌐 Network Mode:     Static IP ($IP_ADDRESS)" >> /etc/motd
    else
        echo "🌐 Network Mode:     DHCP" >> /etc/motd
    fi
    
    echo "" >> /etc/motd
    echo "═══════════════════════════════════════════════════════════════════════════════" >> /etc/motd
    echo "" >> /etc/motd
}

# Function to set user permissions based on PUID/PGID
setup_user_permissions() {
    local puid=${PUID:-0}
    local pgid=${PGID:-0}
    
    echo "Setting up user permissions with PUID=$puid, PGID=$pgid"
    
    # Only modify if not using root (0:0)
    if [ "$puid" != "0" ] || [ "$pgid" != "0" ]; then
        # Create group if it doesn't exist
        if ! getent group "$pgid" >/dev/null; then
            groupadd -g "$pgid" mgmtuser
        fi
        
        # Create user if it doesn't exist
        if ! getent passwd "$puid" >/dev/null; then
            useradd -u "$puid" -g "$pgid" -d /root -s "$(which bash)" mgmtuser
        fi
        
        # Change ownership of config directory
        chown -R "$puid:$pgid" /root/config 2>/dev/null || true
    fi
}

# Function to set password from file or environment variable
set_password() {
    local password=""
    
    if [[ -n "$PASSWORD_FILE" && -f "$PASSWORD_FILE" ]]; then
        password=$(cat "$PASSWORD_FILE" | tr -d '\n\r')
        echo "Using password from file: $PASSWORD_FILE"
    elif [[ -n "$PASSWORD" ]]; then
        password="$PASSWORD"
        echo "Using password from environment variable"
    else
        password="password"
        echo "Using default password"
    fi
    
    echo "root:$password" | chpasswd
}

# Function to setup home directory symlinks
setup_home_directory() {
    # Create config directory if it doesn't exist
    mkdir -p /root/config
    
    # List of files/directories to symlink from mounted config
    declare -a config_files=(
        ".bashrc"
        ".zshrc" 
        ".vimrc"
        ".tmux.conf"
        ".kube"
        ".ssh"
        ".gitconfig"
        ".terraformrc"
        ".helm"
        "tailscale-state"
    )
    
    # Create symlinks for configuration files
    for file in "${config_files[@]}"; do
        if [[ -f "/root/config/$file" || -d "/root/config/$file" ]]; then
            # Remove existing file/directory if it exists and isn't already a symlink
            if [[ -e "/root/$file" && ! -L "/root/$file" ]]; then
                rm -rf "/root/$file"
            fi
            # Create symlink if it doesn't exist
            if [[ ! -L "/root/$file" ]]; then
                ln -sf "/root/config/$file" "/root/$file"
                echo "Created symlink for $file"
            fi
        fi
    done
    
    # Ensure .kube directory exists with proper permissions
    mkdir -p /root/config/.kube /root/.kube
    chmod 700 /root/config/.kube 2>/dev/null || true
    
    # Ensure .ssh directory exists with proper permissions
    mkdir -p /root/config/.ssh /root/.ssh
    chmod 700 /root/config/.ssh 2>/dev/null || true
}

# Function to setup fstab
setup_fstab() {
    if [[ -f "/root/config/fstab" ]]; then
        echo "Setting up fstab from mounted config"
        cp /root/config/#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' | tr '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::$'
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0 
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' | tr '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::$'
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0 
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' | tr '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::$'
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0 
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0 ]] && echo "IPv6 DNS: ${dns6_servers[*]}"
    
    # Apply network configuration
    local interface="eth0"
    
    # Configure IPv4
    echo "Configuring IPv4 address: $IP_ADDRESS on $interface"
    ip addr add "$IP_ADDRESS" dev "$interface" || echo "Warning: Failed to set IPv4 address"
    ip link set "$interface" up
    
    # Configure IPv4 gateway
    if [[ -n "$IP_GATEWAY" ]]; then
        echo "Setting IPv4 gateway: $IP_GATEWAY"
        ip route add default via "$IP_GATEWAY" || echo "Warning: Failed to set IPv4 gateway"
    fi
    
    # Configure IPv6
    if [[ -n "$IP_ADDRESS6" ]]; then
        echo "Configuring IPv6 address: $IP_ADDRESS6 on $interface"
        ip -6 addr add "$IP_ADDRESS6" dev "$interface" || echo "Warning: Failed to set IPv6 address"
    fi
    
    # Configure IPv6 gateway
    if [[ -n "$IP_GATEWAY6" ]]; then
        echo "Setting IPv6 gateway: $IP_GATEWAY6"
        ip -6 route add default via "$IP_GATEWAY6" || echo "Warning: Failed to set IPv6 gateway"
    fi
    
    # Configure DNS
    if [[ ${#dns4_servers[@]} -gt 0 ]] || [[ ${#dns6_servers[@]} -gt 0 ]]; then
        echo "Configuring DNS servers..."
        echo "# Generated by MagicShell" > /etc/resolv.conf
        for dns in "${dns4_servers[@]}" "${dns6_servers[@]}"; do
            echo "nameserver $dns" >> /etc/resolv.conf
        done
    fi
    
    return 0
}

# Function to setup hostname
setup_hostname() {
    local target_hostname="${HOSTNAME:-MagicShell}"
    echo "Setting hostname to: $target_hostname"
    echo "$target_hostname" > /etc/hostname
    hostname "$target_hostname"
    
    # Update /etc/hosts
    echo "127.0.0.1 localhost $target_hostname" > /etc/hosts
    echo "::1 localhost ip6-localhost ip6-loopback $target_hostname" >> /etc/hosts
}

# Function to setup custom MOTD
setup_motd() {
    cat > /etc/motd << 'EOF'

███╗   ███╗ █████╗  ██████╗ ██╗ ██████╗███████╗██╗  ██╗███████╗██╗     ██╗     
████╗ ████║██╔══██╗██╔════╝ ██║██╔════╝██╔════╝██║  ██║██╔════╝██║     ██║     
██╔████╔██║███████║██║  ███╗██║██║     ███████╗███████║█████╗  ██║     ██║     
██║╚██╔╝██║██╔══██║██║   ██║██║██║     ╚════██║██╔══██║██╔══╝  ██║     ██║     
██║ ╚═╝ ██║██║  ██║╚██████╔╝██║╚██████╗███████║██║  ██║███████╗███████╗███████╗
╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝

🎭 MagicShell - Universal Infrastructure Management Container

📊 Tool Versions:    Run 'huh' to see all installed tools and versions
🔍 Tool Details:     Run 'huh --app <tool>' for detailed information  
📦 Repository:       https://github.com/EricZarnosky/MagicShell
🏗️  Build Info:      Check environment variables BUILD_DATE and VCS_REF

🚀 Quick Start:
   • List tools:      huh
   • Cloud login:     aws configure
   • Kubernetes:      kubectl get nodes, k9s
   • Infrastructure:  tofu plan, terraform apply
   • Secrets:         vault server -dev

EOF

    # Add build info if available
    if [ -n "$BUILD_DATE" ]; then
        echo "🕐 Build Date:       $BUILD_DATE" >> /etc/motd
    fi
    if [ -n "$VCS_REF" ]; then
        echo "📝 Git Commit:       $VCS_REF" >> /etc/motd
    fi
    
    # Add network info
    local normalized_mac
    if normalized_mac=$(normalize_mac "$MAC"); then
        echo "🌐 MAC Address:      $normalized_mac" >> /etc/motd
    fi
    
    if [[ -n "$IP_ADDRESS" ]]; then
        echo "🌐 Network Mode:     Static IP ($IP_ADDRESS)" >> /etc/motd
    else
        echo "🌐 Network Mode:     DHCP" >> /etc/motd
    fi
    
    echo "" >> /etc/motd
    echo "═══════════════════════════════════════════════════════════════════════════════" >> /etc/motd
    echo "" >> /etc/motd
}

# Function to set user permissions based on PUID/PGID
setup_user_permissions() {
    local puid=${PUID:-0}
    local pgid=${PGID:-0}
    
    echo "Setting up user permissions with PUID=$puid, PGID=$pgid"
    
    # Only modify if not using root (0:0)
    if [ "$puid" != "0" ] || [ "$pgid" != "0" ]; then
        # Create group if it doesn't exist
        if ! getent group "$pgid" >/dev/null; then
            groupadd -g "$pgid" mgmtuser
        fi
        
        # Create user if it doesn't exist
        if ! getent passwd "$puid" >/dev/null; then
            useradd -u "$puid" -g "$pgid" -d /root -s "$(which bash)" mgmtuser
        fi
        
        # Change ownership of config directory
        chown -R "$puid:$pgid" /root/config 2>/dev/null || true
    fi
}

# Function to set password from file or environment variable
set_password() {
    local password=""
    
    if [[ -n "$PASSWORD_FILE" && -f "$PASSWORD_FILE" ]]; then
        password=$(cat "$PASSWORD_FILE" | tr -d '\n\r')
        echo "Using password from file: $PASSWORD_FILE"
    elif [[ -n "$PASSWORD" ]]; then
        password="$PASSWORD"
        echo "Using password from environment variable"
    else
        password="password"
        echo "Using default password"
    fi
    
    echo "root:$password" | chpasswd
}

# Function to setup home directory symlinks
setup_home_directory() {
    # Create config directory if it doesn't exist
    mkdir -p /root/config
    
    # List of files/directories to symlink from mounted config
    declare -a config_files=(
        ".bashrc"
        ".zshrc" 
        ".vimrc"
        ".tmux.conf"
        ".kube"
        ".ssh"
        ".gitconfig"
        ".terraformrc"
        ".helm"
        "tailscale-state"
    )
    
    # Create symlinks for configuration files
    for file in "${config_files[@]}"; do
        if [[ -f "/root/config/$file" || -d "/root/config/$file" ]]; then
            # Remove existing file/directory if it exists and isn't already a symlink
            if [[ -e "/root/$file" && ! -L "/root/$file" ]]; then
                rm -rf "/root/$file"
            fi
            # Create symlink if it doesn't exist
            if [[ ! -L "/root/$file" ]]; then
                ln -sf "/root/config/$file" "/root/$file"
                echo "Created symlink for $file"
            fi
        fi
    done
    
    # Ensure .kube directory exists with proper permissions
    mkdir -p /root/config/.kube /root/.kube
    chmod 700 /root/config/.kube 2>/dev/null || true
    
    # Ensure .ssh directory exists with proper permissions
    mkdir -p /root/config/.ssh /root/.ssh
    chmod 700 /root/config/.ssh 2>/dev/null || true
}

# Function to setup fstab
setup_fstab() {
    if [[ -f "/root/config/fstab" ]]; then
        echo "Setting up fstab from mounted config"
        cp /root/config/#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' | tr '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::$'
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0 
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure MAC address
configure_mac_address() {
    local normalized_mac
    if ! normalized_mac=$(normalize_mac "$MAC"); then
        echo "WARNING: Invalid MAC address format '$MAC', using default" >&2
        MAC="0D:EC:AF:C0:FF:EE"
        normalized_mac="0D:EC:AF:C0:FF:EE"
    fi
    
    echo "Setting MAC address to: $normalized_mac"
    
    # Find the primary network interface
    local interface=$(ip route | grep '^default' | awk '{print $5}' | head -1)
    if [[ -z "$interface" ]]; then
        interface="eth0"  # fallback
    fi
    
    # Set MAC address
    ip link set dev "$interface" down 2>/dev/null || true
    ip link set dev "$interface" address "$normalized_mac" 2>/dev/null || echo "Warning: Could not set MAC address"
    ip link set dev "$interface" up 2>/dev/null || true
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' | tr '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::$'
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0 
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' | tr '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::$'
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0 
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0 ]] && echo "IPv6 DNS: ${dns6_servers[*]}"
    
    # Apply network configuration
    local interface="eth0"
    
    # Configure IPv4
    echo "Configuring IPv4 address: $IP_ADDRESS on $interface"
    ip addr add "$IP_ADDRESS" dev "$interface" || echo "Warning: Failed to set IPv4 address"
    ip link set "$interface" up
    
    # Configure IPv4 gateway
    if [[ -n "$IP_GATEWAY" ]]; then
        echo "Setting IPv4 gateway: $IP_GATEWAY"
        ip route add default via "$IP_GATEWAY" || echo "Warning: Failed to set IPv4 gateway"
    fi
    
    # Configure IPv6
    if [[ -n "$IP_ADDRESS6" ]]; then
        echo "Configuring IPv6 address: $IP_ADDRESS6 on $interface"
        ip -6 addr add "$IP_ADDRESS6" dev "$interface" || echo "Warning: Failed to set IPv6 address"
    fi
    
    # Configure IPv6 gateway
    if [[ -n "$IP_GATEWAY6" ]]; then
        echo "Setting IPv6 gateway: $IP_GATEWAY6"
        ip -6 route add default via "$IP_GATEWAY6" || echo "Warning: Failed to set IPv6 gateway"
    fi
    
    # Configure DNS
    if [[ ${#dns4_servers[@]} -gt 0 ]] || [[ ${#dns6_servers[@]} -gt 0 ]]; then
        echo "Configuring DNS servers..."
        echo "# Generated by MagicShell" > /etc/resolv.conf
        for dns in "${dns4_servers[@]}" "${dns6_servers[@]}"; do
            echo "nameserver $dns" >> /etc/resolv.conf
        done
    fi
    
    return 0
}

# Function to setup hostname
setup_hostname() {
    local target_hostname="${HOSTNAME:-MagicShell}"
    echo "Setting hostname to: $target_hostname"
    echo "$target_hostname" > /etc/hostname
    hostname "$target_hostname"
    
    # Update /etc/hosts
    echo "127.0.0.1 localhost $target_hostname" > /etc/hosts
    echo "::1 localhost ip6-localhost ip6-loopback $target_hostname" >> /etc/hosts
}

# Function to setup custom MOTD
setup_motd() {
    cat > /etc/motd << 'EOF'

███╗   ███╗ █████╗  ██████╗ ██╗ ██████╗███████╗██╗  ██╗███████╗██╗     ██╗     
████╗ ████║██╔══██╗██╔════╝ ██║██╔════╝██╔════╝██║  ██║██╔════╝██║     ██║     
██╔████╔██║███████║██║  ███╗██║██║     ███████╗███████║█████╗  ██║     ██║     
██║╚██╔╝██║██╔══██║██║   ██║██║██║     ╚════██║██╔══██║██╔══╝  ██║     ██║     
██║ ╚═╝ ██║██║  ██║╚██████╔╝██║╚██████╗███████║██║  ██║███████╗███████╗███████╗
╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝

🎭 MagicShell - Universal Infrastructure Management Container

📊 Tool Versions:    Run 'huh' to see all installed tools and versions
🔍 Tool Details:     Run 'huh --app <tool>' for detailed information  
📦 Repository:       https://github.com/EricZarnosky/MagicShell
🏗️  Build Info:      Check environment variables BUILD_DATE and VCS_REF

🚀 Quick Start:
   • List tools:      huh
   • Cloud login:     aws configure
   • Kubernetes:      kubectl get nodes, k9s
   • Infrastructure:  tofu plan, terraform apply
   • Secrets:         vault server -dev

EOF

    # Add build info if available
    if [ -n "$BUILD_DATE" ]; then
        echo "🕐 Build Date:       $BUILD_DATE" >> /etc/motd
    fi
    if [ -n "$VCS_REF" ]; then
        echo "📝 Git Commit:       $VCS_REF" >> /etc/motd
    fi
    
    # Add network info
    local normalized_mac
    if normalized_mac=$(normalize_mac "$MAC"); then
        echo "🌐 MAC Address:      $normalized_mac" >> /etc/motd
    fi
    
    if [[ -n "$IP_ADDRESS" ]]; then
        echo "🌐 Network Mode:     Static IP ($IP_ADDRESS)" >> /etc/motd
    else
        echo "🌐 Network Mode:     DHCP" >> /etc/motd
    fi
    
    echo "" >> /etc/motd
    echo "═══════════════════════════════════════════════════════════════════════════════" >> /etc/motd
    echo "" >> /etc/motd
}

# Function to set user permissions based on PUID/PGID
setup_user_permissions() {
    local puid=${PUID:-0}
    local pgid=${PGID:-0}
    
    echo "Setting up user permissions with PUID=$puid, PGID=$pgid"
    
    # Only modify if not using root (0:0)
    if [ "$puid" != "0" ] || [ "$pgid" != "0" ]; then
        # Create group if it doesn't exist
        if ! getent group "$pgid" >/dev/null; then
            groupadd -g "$pgid" mgmtuser
        fi
        
        # Create user if it doesn't exist
        if ! getent passwd "$puid" >/dev/null; then
            useradd -u "$puid" -g "$pgid" -d /root -s "$(which bash)" mgmtuser
        fi
        
        # Change ownership of config directory
        chown -R "$puid:$pgid" /root/config 2>/dev/null || true
    fi
}

# Function to set password from file or environment variable
set_password() {
    local password=""
    
    if [[ -n "$PASSWORD_FILE" && -f "$PASSWORD_FILE" ]]; then
        password=$(cat "$PASSWORD_FILE" | tr -d '\n\r')
        echo "Using password from file: $PASSWORD_FILE"
    elif [[ -n "$PASSWORD" ]]; then
        password="$PASSWORD"
        echo "Using password from environment variable"
    else
        password="password"
        echo "Using default password"
    fi
    
    echo "root:$password" | chpasswd
}

# Function to setup home directory symlinks
setup_home_directory() {
    # Create config directory if it doesn't exist
    mkdir -p /root/config
    
    # List of files/directories to symlink from mounted config
    declare -a config_files=(
        ".bashrc"
        ".zshrc" 
        ".vimrc"
        ".tmux.conf"
        ".kube"
        ".ssh"
        ".gitconfig"
        ".terraformrc"
        ".helm"
        "tailscale-state"
    )
    
    # Create symlinks for configuration files
    for file in "${config_files[@]}"; do
        if [[ -f "/root/config/$file" || -d "/root/config/$file" ]]; then
            # Remove existing file/directory if it exists and isn't already a symlink
            if [[ -e "/root/$file" && ! -L "/root/$file" ]]; then
                rm -rf "/root/$file"
            fi
            # Create symlink if it doesn't exist
            if [[ ! -L "/root/$file" ]]; then
                ln -sf "/root/config/$file" "/root/$file"
                echo "Created symlink for $file"
            fi
        fi
    done
    
    # Ensure .kube directory exists with proper permissions
    mkdir -p /root/config/.kube /root/.kube
    chmod 700 /root/config/.kube 2>/dev/null || true
    
    # Ensure .ssh directory exists with proper permissions
    mkdir -p /root/config/.ssh /root/.ssh
    chmod 700 /root/config/.ssh 2>/dev/null || true
}

# Function to setup fstab
setup_fstab() {
    if [[ -f "/root/config/fstab" ]]; then
        echo "Setting up fstab from mounted config"
        cp /root/config/#!/bin/bash

# Function to normalize MAC address to standard format (XX:XX:XX:XX:XX:XX)
normalize_mac() {
    local mac="$1"
    
    # Remove all delimiters and convert to uppercase
    mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' | tr '[:upper:]')
    
    # Check if we have exactly 12 hex characters
    if [[ ! "$mac" =~ ^[0-9A-F]{12}$ ]]; then
        echo "ERROR: Invalid MAC address format: $1" >&2
        return 1
    fi
    
    # Format as XX:XX:XX:XX:XX:XX
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
}

# Function to validate IPv4 address
validate_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi
    
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]] || [[ "$octet" =~ ^0[0-9]+ ]]; then
            return 1
        fi
    done
    return 0
}

# Function to validate IPv6 address (basic validation)
validate_ipv6() {
    local ip="$1"
    # Basic IPv6 validation - matches most common formats
    local regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$|^::1$|^::$'
    [[ "$ip" =~ $regex ]]
}

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local ip_version="$2"  # 4 or 6
    
    if [[ ! "$cidr" =~ ^(.+)/([0-9]+)$ ]]; then
        return 1
    fi
    
    local ip="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"
    
    if [[ "$ip_version" == "4" ]]; then
        validate_ipv4 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 32 ]]
    else
        validate_ipv6 "$ip" && [[ "$prefix" -ge 0 && "$prefix" -le 128 ]]
    fi
}

# Function to parse and validate DNS servers
parse_dns_servers() {
    local dns_input="$1"
    local ip_version="$2"  # 4 or 6
    local -n dns_array=$3
    
    # Split by comma, space, or both
    IFS=', ' read -ra servers <<< "$dns_input"
    
    for server in "${servers[@]}"; do
        # Skip empty entries
        [[ -z "$server" ]] && continue
        
        if [[ "$ip_version" == "4" ]]; then
            if validate_ipv4 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv4 DNS server: $server" >&2
                return 1
            fi
        else
            if validate_ipv6 "$server"; then
                dns_array+=("$server")
            else
                echo "ERROR: Invalid IPv6 DNS server: $server" >&2
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to configure static networking
configure_static_network() {
    echo "Configuring static network settings..."
    
    # Validate required parameters
    if [[ -z "$IP_ADDRESS" ]]; then
        echo "ERROR: IP_ADDRESS is required for static networking" >&2
        return 1
    fi
    
    if ! validate_cidr "$IP_ADDRESS" "4"; then
        echo "ERROR: Invalid IPv4 CIDR format: $IP_ADDRESS" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY" ]] && ! validate_ipv4 "$IP_GATEWAY"; then
        echo "ERROR: Invalid IPv4 gateway: $IP_GATEWAY" >&2
        return 1
    fi
    
    if [[ -n "$IP_ADDRESS6" ]] && ! validate_cidr "$IP_ADDRESS6" "6"; then
        echo "ERROR: Invalid IPv6 CIDR format: $IP_ADDRESS6" >&2
        return 1
    fi
    
    if [[ -n "$IP_GATEWAY6" ]] && ! validate_ipv6 "$IP_GATEWAY6"; then
        echo "ERROR: Invalid IPv6 gateway: $IP_GATEWAY6" >&2
        return 1
    fi
    
    # Parse DNS servers
    local dns4_servers=()
    local dns6_servers=()
    
    if [[ -n "$IP_DNS" ]]; then
        if ! parse_dns_servers "$IP_DNS" "4" dns4_servers; then
            return 1
        fi
    fi
    
    if [[ -n "$IP_DNS6" ]]; then
        if ! parse_dns_servers "$IP_DNS6" "6" dns6_servers; then
            return 1
        fi
    fi
    
    echo "Static network configuration validated successfully"
    echo "IPv4: $IP_ADDRESS"
    [[ -n "$IP_GATEWAY" ]] && echo "IPv4 Gateway: $IP_GATEWAY"
    [[ -n "$IP_ADDRESS6" ]] && echo "IPv6: $IP_ADDRESS6"
    [[ -n "$IP_GATEWAY6" ]] && echo "IPv6 Gateway: $IP_GATEWAY6"
    [[ ${#dns4_servers[@]} -gt 0 ]] && echo "IPv4 DNS: ${dns4_servers[*]}"
    [[ ${#dns6_servers[@]} -gt 0