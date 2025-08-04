#!/bin/bash

# Hadoop HA Cluster Environment Check Script
# Used to verify if the system meets deployment requirements

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
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check result statistics
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Record check results
record_result() {
    if [ "$1" == "pass" ]; then
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        log_success "$2"
    elif [ "$1" == "fail" ]; then
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        log_error "$2"
    else
        WARNINGS=$((WARNINGS + 1))
        log_warning "$2"
    fi
}

echo "========================================"
echo "    Hadoop HA Cluster Environment Check"
echo "========================================"
echo

# 1. Check operating system
log_info "Checking operating system..."
    if [ -f /etc/os-release ]; then
        OS_NAME=$(grep "^NAME=" /etc/os-release | cut -d'"' -f2)
        OS_VERSION=$(grep "^VERSION=" /etc/os-release | cut -d'"' -f2)
        record_result "pass" "Operating system: $OS_NAME $OS_VERSION"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_NAME="macOS"
        OS_VERSION=$(sw_vers -productVersion)
        record_result "warn" "Operating system: $OS_NAME $OS_VERSION (This script is primarily designed for Linux)"
    else
        record_result "fail" "Unable to identify operating system"
    fi

    # 2. Check system architecture
    log_info "Checking system architecture..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" || "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        record_result "pass" "System architecture: $ARCH (Supported)"
    else
        record_result "warn" "System architecture: $ARCH (May not be supported)"
    fi

    # 3. Check memory
    log_info "Checking system memory..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    MEMORY_BYTES=$(sysctl -n hw.memsize)
    MEMORY_GB=$((MEMORY_BYTES / 1024 / 1024 / 1024))
elif command -v free >/dev/null 2>&1; then
    # Linux
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
else
    MEMORY_GB="unknown"
fi

if [ "$MEMORY_GB" != "unknown" ] && [ "$MEMORY_GB" -ge 4 ]; then
    record_result "pass" "System memory: ${MEMORY_GB}GB (Satisfies requirements)"
elif [ "$MEMORY_GB" != "unknown" ] && [ "$MEMORY_GB" -ge 2 ]; then
    record_result "warn" "System memory: ${MEMORY_GB}GB (Recommended at least 4GB)"
elif [ "$MEMORY_GB" != "unknown" ]; then
    record_result "fail" "System memory: ${MEMORY_GB}GB (Insufficient, requires at least 4GB)"
else
    record_result "warn" "Unable to detect system memory"
fi

# 4. Check disk space
log_info "Checking disk space..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    DISK_GB=$(df -g . | awk 'NR==2 {print $4}')
else
    # Linux
    DISK_GB=$(df -BG . 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G' 2>/dev/null || echo "unknown")
fi

if [ "$DISK_GB" != "unknown" ] && [ "$DISK_GB" -ge 10 ]; then
    record_result "pass" "Available disk space: ${DISK_GB}GB (Satisfies requirements)"
elif [ "$DISK_GB" != "unknown" ]; then
    record_result "fail" "Available disk space: ${DISK_GB}GB (Insufficient, requires at least 10GB)"
else
    record_result "warn" "Unable to detect disk space"
fi

# 5. Check CPU cores
log_info "Check CPU cores..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CPU_CORES=$(sysctl -n hw.ncpu)
elif command -v nproc >/dev/null 2>&1; then
    # Linux
    CPU_CORES=$(nproc)
else
    CPU_CORES="unknown"
fi

if [ "$CPU_CORES" != "unknown" ] && [ "$CPU_CORES" -ge 2 ]; then
    record_result "pass" "CPU cores: $CPU_CORES (Satisfies requirements)"
elif [ "$CPU_CORES" != "unknown" ]; then
    record_result "warn" "CPU cores: $CPU_CORES (Recommended at least 2 cores)"
else
    record_result "warn" "Unable to detect CPU cores"
fi

# 6. Check Docker installation
log_info "Check Docker installation status..."
if command -v docker >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
    record_result "pass" "Docker installed: $DOCKER_VERSION"
    
    # Check Docker service status
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - Check if Docker is Available
        if docker info >/dev/null 2>&1; then
            record_result "pass" "Docker service is running"
        else
            record_result "fail" "Docker service not running, please start Docker Desktop"
        fi
    else
        # Linux - Use systemctl to check
        if systemctl is-active --quiet docker; then
            record_result "pass" "Docker service is running"
        else
            record_result "fail" "Docker service not running, please start: sudo systemctl start docker"
        fi
    fi
    
    # Check if user is in docker group
    if groups | grep -q docker; then
        record_result "pass" "Current user is in docker group"
    else
        record_result "fail" "Current user not in docker group, please execute: sudo usermod -aG docker \$USER"
    fi
else
    record_result "fail" "Docker not installed, please refer to README.md to install Docker"
fi

# 7. Check Docker Compose installation
log_info "Check Docker Compose installation status..."
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | tr -d ',')
    record_result "pass" "Docker Compose installed: $COMPOSE_VERSION"
else
    record_result "fail" "Docker Compose not installed, please refer to README.md to install Docker Compose"
fi

# 8. Check port occupancy
log_info "Check if critical ports are occupied..."
PORTS=(80 9820 9821 9866 9867 9868 8030 8031)
for port in "${PORTS[@]}"; do
    PORT_USED=false
    
    # Check if port is occupied (compatible with different systems)
    if command -v lsof >/dev/null 2>&1; then
        # Use lsof to check (supported by both macOS and Linux)
        if lsof -i :$port >/dev/null 2>&1; then
            PORT_USED=true
        fi
    elif command -v netstat >/dev/null 2>&1; then
        # Use netstat to check (Linux)
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            PORT_USED=true
        fi
    elif command -v ss >/dev/null 2>&1; then
        # Use ss to check (modern Linux)
        if ss -tlnp 2>/dev/null | grep -q ":$port "; then
            PORT_USED=true
        fi
    fi
    
    if $PORT_USED; then
        record_result "warn" "Port $port is occupied, may cause conflicts"
    else
        record_result "pass" "Port $port Available"
    fi
done

# 9. Check network connection
log_info "Check network connection..."
if ping -c 1 registry-1.docker.io >/dev/null 2>&1; then
    record_result "pass" "Can access Docker Hub"
elif ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    record_result "warn" "Network connection normal but cannot access Docker Hub, may need to configure mirror source"
else
    record_result "fail" "Network connection abnormal, cannot access external network"
fi

# 10. Check system limits
log_info "Checking system limits..."
NOFILE_LIMIT=$(ulimit -n)
if [ "$NOFILE_LIMIT" -ge 65536 ]; then
    record_result "pass" "File descriptor limit: $NOFILE_LIMIT (Satisfies requirements)"
elif [ "$NOFILE_LIMIT" -ge 1024 ]; then
    record_result "warn" "File descriptor limit: $NOFILE_LIMIT (Recommended to set to 65536)"
else
    record_result "fail" "File descriptor limit: $NOFILE_LIMIT (Too low, needs to be increased)"
fi

# 11. Check kernel parameters
log_info "Checking kernel parameters..."
MAX_MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null || echo "unknown")
if [ "$MAX_MAP_COUNT" != "unknown" ] && [ "$MAX_MAP_COUNT" -ge 262144 ]; then
    record_result "pass" "vm.max_map_count: $MAX_MAP_COUNT (Satisfies requirements)"
else
    record_result "warn" "vm.max_map_count: $MAX_MAP_COUNT (Recommended to set to 262144)"
fi

# 12. Check required commands
log_info "Checking required commands..."
REQUIRED_COMMANDS=(curl wget git tar)
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        record_result "pass" "Command $cmd is installed"
    else
        record_result "warn" "Command $cmd not installed, recommended to install"
    fi
done

echo
echo "========================================"
echo "             Check Results Summary"
echo "========================================"
echo -e "${GREEN}Passed checks: $CHECKS_PASSED${NC}"
echo -e "${YELLOW}Warning items: $WARNINGS${NC}"
echo -e "${RED}Failed items: $CHECKS_FAILED${NC}"
echo

# Provide recommendations based on check results
if [ "$CHECKS_FAILED" -eq 0 ]; then
    if [ "$WARNINGS" -eq 0 ]; then
        echo -e "${GREEN}🎉 Congratulations! Your system fully meets deployment requirements${NC}"
        echo -e "${GREEN}You can directly run ./start-cluster.sh to start the cluster${NC}"
    else
        echo -e "${YELLOW}⚠️  Your system basically meets requirements, but there are some recommended improvements${NC}"
        echo -e "${YELLOW}You can run ./start-cluster.sh to start the cluster, but it's recommended to resolve warnings first${NC}"
    fi
else
    echo -e "${RED}❌ Your system does not yet meet deployment requirements${NC}"
    echo -e "${RED}Please resolve failed items before attempting to deploy the cluster${NC}"
    echo
    echo "Common solutions:"
    echo "1. Install Docker: Refer to installation instructions in README.md"
    echo "2. Start Docker service: sudo systemctl start docker"
    echo "3. Join docker group: sudo usermod -aG docker \$USER && newgrp docker"
    echo "4. Install Docker Compose: Refer to installation instructions in README.md"
    echo "5. Free up ports: Stop services occupying ports"
    echo "6. Increase system resources: Ensure sufficient memory and disk space"
fi

echo
echo "For detailed deployment instructions, please refer to: README.md"
echo "========================================"

exit $CHECKS_FAILED 