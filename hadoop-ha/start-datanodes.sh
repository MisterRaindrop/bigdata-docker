#!/bin/bash

# DataNode startup and check script
# When DataNode is not started properly, users can run this script to manually start it

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

# Check if containers are running
check_containers() {
    log_info "Checking if containers are running..."
    
    local containers=("datanode1" "datanode2" "datanode3")
    local all_running=true
    
    for container in "${containers[@]}"; do
        if docker ps | grep -q "$container"; then
            log_success "$container container is running"
        else
            log_error "$container container is not running"
            all_running=false
        fi
    done
    
    if [ "$all_running" = false ]; then
        log_error "Some containers are not running. Please start the cluster first:"
        log_info "  docker-compose up -d"
        exit 1
    fi
}

# Check DataNode processes
check_datanode_processes() {
    log_info "Checking DataNode processes..."
    
    local containers=("datanode1" "datanode2" "datanode3")
    local all_running=true
    
    for container in "${containers[@]}"; do
        if docker exec "$container" ps aux | grep -q "datanode"; then
            log_success "$container DataNode process is running"
        else
            log_warning "$container DataNode process is not running"
            all_running=false
        fi
    done
    
    if [ "$all_running" = true ]; then
        log_success "All DataNodes are running!"
        return 0
    else
        log_warning "Some DataNodes are not running. Will attempt to start them."
        return 1
    fi
}

# Fix permissions
fix_permissions() {
    log_info "Fixing DataNode directory permissions..."
    
    local containers=("datanode1" "datanode2" "datanode3")
    
    for container in "${containers[@]}"; do
        log_info "Fixing permissions for $container..."
        if docker exec -u root "$container" bash -c "chmod -R 755 /hadoop && chown -R hadoop:hadoop /hadoop"; then
            log_success "$container permissions fixed"
        else
            log_error "Failed to fix permissions for $container"
            return 1
        fi
    done
}

# Start DataNode
start_datanodes() {
    log_info "Starting DataNode processes..."
    
    local containers=("datanode1" "datanode2" "datanode3")
    
    for container in "${containers[@]}"; do
        log_info "Starting DataNode on $container..."
        if docker exec -d "$container" hdfs datanode; then
            log_success "$container DataNode started"
        else
            log_error "Failed to start DataNode on $container"
            return 1
        fi
    done
}

# Wait for DataNode to start
wait_for_datanodes() {
    log_info "Waiting for DataNodes to start..."
    sleep 10
    
    local containers=("datanode1" "datanode2" "datanode3")
    local max_attempts=6
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local all_running=true
        
        for container in "${containers[@]}"; do
            if ! docker exec "$container" ps aux | grep -q "datanode"; then
                all_running=false
                break
            fi
        done
        
        if [ "$all_running" = true ]; then
            log_success "All DataNodes are running!"
            return 0
        fi
        
        log_info "Attempt $attempt/$max_attempts: Waiting for DataNodes to start..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    log_error "DataNodes failed to start after $max_attempts attempts"
    return 1
}

# Check HDFS status
check_hdfs_status() {
    log_info "Checking HDFS cluster status..."
    
    if docker exec namenode1 hdfs dfsadmin -report > /dev/null 2>&1; then
        log_success "HDFS cluster is accessible"
        
        # Display simplified status report
        echo ""
        log_info "HDFS Cluster Status:"
        docker exec namenode1 hdfs dfsadmin -report | grep -E "(Live datanodes|Configured Capacity|Present Capacity|DFS Used%)" | head -10
    else
        log_error "Cannot access HDFS cluster"
        return 1
    fi
}

# Show usage information
show_usage() {
    echo ""
    log_info "Usage:"
    echo "  $0                    # Check and start DataNode"
    echo "  $0 --check-only       # Check status only, do not start"
    echo "  $0 --help             # Show this help information"
    echo ""
    log_info "This script will:"
    echo "  1. Check if containers are running"
    echo "  2. Check if DataNode processes are running"
    echo "  3. Fix permissions if needed"
    echo "  4. Start DataNode processes if not running"
    echo "  5. Verify HDFS cluster status"
    echo ""
}

# Main function
main() {
    echo "🔧 DataNode Startup and Check Script"
    echo "====================================="
    
    # Parse parameters
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_usage
        exit 0
    fi
    
    local check_only=false
    if [ "$1" = "--check-only" ]; then
        check_only=true
    fi
    
    # Check container status
    check_containers
    
    # Check DataNode processes
    if check_datanode_processes; then
        log_success "All DataNodes are already running!"
        check_hdfs_status
        exit 0
    fi
    
    if [ "$check_only" = true ]; then
        log_info "Check-only mode: DataNodes are not running but will not be started"
        exit 1
    fi
    
    # Fix permissions
    fix_permissions
    
    # Start DataNode
    start_datanodes
    
    # Wait for startup
    if wait_for_datanodes; then
        log_success "All DataNodes started successfully!"
    else
        log_error "Failed to start DataNodes"
        exit 1
    fi
    
    # Check HDFS status
    check_hdfs_status
    
    echo ""
    log_success "DataNode startup completed!"
    log_info "You can now use HDFS commands:"
    log_info "  docker exec namenode1 hdfs dfs -ls /"
    log_info "  docker exec namenode1 hdfs dfsadmin -report"
}

# Run main function
main "$@" 