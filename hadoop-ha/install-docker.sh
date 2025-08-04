#!/bin/bash

# Docker and Docker Compose automatic installation script
# Supports mainstream distributions like CentOS, Ubuntu, Debian

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        log_error "Unable to detect operating system"
        exit 1
    fi
    
    log_info "Detected operating system: $OS $VER"
}

# Check if running as root user or has sudo privileges
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    elif command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
        log_info "Will use sudo privileges for installation"
    else
        log_error "Root privileges or sudo access required to install Docker"
        exit 1
    fi
}

# Install Docker on CentOS/RHEL systems
install_docker_centos() {
    log_info "Installing Docker on CentOS/RHEL system..."
    
    # Remove old versions
    $SUDO yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true
    
    # Install dependencies
    $SUDO yum install -y yum-utils device-mapper-persistent-data lvm2
    
    # Add Docker repository
    $SUDO yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Install Docker
    $SUDO yum install -y docker-ce docker-ce-cli containerd.io
    
    log_success "Docker installation completed"
}

# Install Docker on Ubuntu/Debian systems
install_docker_ubuntu() {
    log_info "Installing Docker on Ubuntu/Debian system..."
    
    # Update package index
    $SUDO apt update
    
    # Remove old versions
    $SUDO apt remove -y docker docker-engine docker.io containerd runc || true
    
    # Install dependencies
    $SUDO apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/$OS/gpg | $SUDO gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index and install Docker
    $SUDO apt update
    $SUDO apt install -y docker-ce docker-ce-cli containerd.io
    
    log_success "Docker installation completed"
}

# Install Docker Compose
install_docker_compose() {
    log_info "Installing Docker Compose..."
    
    # Check if already installed
    if command -v docker-compose >/dev/null 2>&1; then
        log_warning "Docker Compose already installed: $(docker-compose --version)"
        return
    fi
    
    # Get latest version
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    
    if [ -z "$COMPOSE_VERSION" ]; then
        log_warning "Unable to get latest version, using default version"
        COMPOSE_VERSION="v2.20.0"
    fi
    
    log_info "Downloading Docker Compose $COMPOSE_VERSION..."
    
    # Download Docker Compose
    $SUDO curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Set execute permissions
    $SUDO chmod +x /usr/local/bin/docker-compose
    
    # Create soft link
    $SUDO ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose installation completed: $(docker-compose --version)"
}

# Configure Docker service
configure_docker() {
    log_info "Configuring Docker service..."
    
    # Start and enable Docker service
    $SUDO systemctl start docker
    $SUDO systemctl enable docker
    
    # Add current user to docker group
    $SUDO usermod -aG docker $USER
    
    log_success "Docker service configuration completed"
    log_warning "Please log out and log back in or run 'newgrp docker' to activate docker group permissions"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check Docker version
    if docker --version >/dev/null 2>&1; then
        log_success "Docker installation verification passed: $(docker --version)"
    else
        log_error "Docker installation verification failed"
        return 1
    fi
    
    # Check Docker Compose version
    if docker-compose --version >/dev/null 2>&1; then
        log_success "Docker Compose installation verification passed: $(docker-compose --version)"
    else
        log_error "Docker Compose installation verification failed"
        return 1
    fi
    
    # Check Docker service status
    if systemctl is-active --quiet docker; then
        log_success "Docker service is running normally"
    else
        log_error "Docker service is not running"
        return 1
    fi
}

# Optimize system configuration
optimize_system() {
    log_info "Optimizing system configuration..."
    
    # Create Docker configuration directory
    $SUDO mkdir -p /etc/docker
    
    # Configure Docker daemon
    cat <<EOF | $SUDO tee /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
    
    # Adjust system parameters
    echo "* soft nofile 65536" | $SUDO tee -a /etc/security/limits.conf
    echo "* hard nofile 65536" | $SUDO tee -a /etc/security/limits.conf
    echo "vm.max_map_count=262144" | $SUDO tee -a /etc/sysctl.conf
    
    $SUDO sysctl -p
    
    # Restart Docker service to apply configuration
    $SUDO systemctl restart docker
    
    log_success "System configuration optimization completed"
}

# Main function
main() {
    echo "========================================"
    echo "    Docker Automatic Installation Script"
    echo "========================================"
    echo
    
    # Detect operating system
    detect_os
    
    # Check permissions
    check_permissions
    
    # Install Docker based on operating system
    case $OS in
        "centos"|"rhel"|"rocky"|"almalinux")
            install_docker_centos
            ;;
        "ubuntu"|"debian")
            install_docker_ubuntu
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    
    # Install Docker Compose
    install_docker_compose
    
    # Configure Docker service
    configure_docker
    
    # Optimize system configuration
    optimize_system
    
    # Verify installation
    if verify_installation; then
        echo
        echo "========================================"
        echo -e "${GREEN}🎉 Docker and Docker Compose installation successful!${NC}"
        echo "========================================"
        echo
        echo "Next steps:"
        echo "1. Log out and log back in or run: newgrp docker"
        echo "2. Run environment check: ./check-environment.sh"
        echo "3. Start Hadoop cluster: ./start-cluster.sh"
        echo
    else
        echo
        echo "========================================"
        echo -e "${RED}❌ Issues occurred during installation${NC}"
        echo "========================================"
        echo "Please check error messages and resolve issues manually"
        exit 1
    fi
}

# Run main function
main "$@" 