#!/bin/bash

# Hadoop HA Cluster Troubleshooting and Repair Script
set -e

echo "🔧 Hadoop HA Cluster Troubleshooting and Repair Tool"
echo "=================================="

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check container status
check_containers() {
    log_info "Checking container status..."
    
    # Check if any containers are running
    if ! docker-compose ps | grep -q "Up"; then
        log_error "No containers are running, please start the cluster first"
        log_info "Run: ./start-cluster.sh"
        return 1
    fi
    
    # Check status of each service container
    local failed_containers=()
    
    for container in zookeeper1 zookeeper2 zookeeper3 journalnode1 journalnode2 journalnode3 namenode1 namenode2; do
        if ! docker-compose ps | grep "$container" | grep -q "Up"; then
            failed_containers+=("$container")
        fi
    done
    
    if [ ${#failed_containers[@]} -gt 0 ]; then
        log_error "The following containers are not running properly:"
        for container in "${failed_containers[@]}"; do
            echo "  - $container"
        done
        return 1
    fi
    
    log_success "All necessary containers are running"
    return 0
}

# Check network connectivity
check_network() {
    log_info "Checking network connectivity..."
    
    # Check if network exists
    if ! docker network ls | grep -q "hadoop-network"; then
        log_error "hadoop-network does not exist"
        return 1
    fi
    
    # Check inter-container network connectivity
    log_info "Testing inter-container network connectivity..."
    
    # Test ZooKeeper connections
    for i in {1..3}; do
        if ! docker exec namenode1 nc -z zookeeper$i 2181 2>/dev/null; then
            log_warning "namenode1 cannot connect to zookeeper$i:2181"
        fi
    done
    
    # Test JournalNode connections
    for i in {1..3}; do
        if ! docker exec namenode1 nc -z journalnode$i 8485 2>/dev/null; then
            log_warning "namenode1 cannot connect to journalnode$i:8485"
        fi
    done
    
    log_success "Network check completed"
}

# Check JournalNode status
check_journalnodes() {
    log_info "Detailed JournalNode status check..."
    
    for i in {1..3}; do
        local container="journalnode$i"
        log_info "Checking $container..."
        
        # Check if container is running
        if ! docker-compose ps | grep "$container" | grep -q "Up"; then
            log_error "$container is not running"
            continue
        fi
        
        # Check if process exists
        if ! docker exec "$container" pgrep -f "journalnode" >/dev/null; then
            log_warning "$container container is running but JournalNode process is not started"
            log_info "Attempting to start $container JournalNode process..."
            docker exec -d "$container" hdfs journalnode
            sleep 5
        fi
        
        # Check if port is listening
        if ! docker exec "$container" netstat -ln 2>/dev/null | grep -q ":8485.*LISTEN"; then
            log_warning "$container JournalNode port 8485 is not listening"
        else
            log_success "$container JournalNode is normal"
        fi
        
        # Show recent logs
        log_info "$container recent logs:"
        docker logs "$container" --tail 5 2>/dev/null | sed 's/^/  /'
    done
}

# Check ZooKeeper status
check_zookeeper() {
    log_info "Checking ZooKeeper cluster status..."
    
    for i in {1..3}; do
        local container="zookeeper$i"
        log_info "Checking $container..."
        
        if docker exec "$container" sh -c 'echo "ruok" | nc localhost 2181' 2>/dev/null | grep -q "imok"; then
            log_success "$container ZooKeeper is normal"
        else
            log_warning "$container ZooKeeper may not be ready"
        fi
    done
}

# Reset and restart JournalNode
reset_journalnodes() {
    log_info "Resetting and restarting JournalNode..."
    
    # Stop all JournalNode processes
    for i in {1..3}; do
        local container="journalnode$i"
        log_info "Stopping $container JournalNode process..."
        docker exec "$container" pkill -f "journalnode" 2>/dev/null || true
        sleep 2
    done
    
    # Clean JournalNode data (optional)
    read -p "Clean JournalNode data? (This will delete all shared edit logs) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Cleaning JournalNode data..."
        for i in {1..3}; do
            docker exec "journalnode$i" rm -rf /hadoop/dfs/journal/* 2>/dev/null || true
        done
    fi
    
    # Restart JournalNode
    for i in {1..3}; do
        local container="journalnode$i"
        log_info "Starting $container JournalNode process..."
        docker exec -d "$container" hdfs journalnode
    done
    
    # Wait for startup completion
    log_info "Waiting for JournalNode startup to complete..."
    sleep 20
    
    # Verify startup status
    for i in {1..3}; do
        local container="journalnode$i"
        if docker exec "$container" netstat -ln 2>/dev/null | grep -q ":8485.*LISTEN"; then
            log_success "$container JournalNode started successfully"
        else
            log_error "$container JournalNode startup failed"
        fi
    done
}

# Complete cluster reset
full_reset() {
    log_warning "Performing complete cluster reset..."
    
    read -p "This will stop all containers and clean all data, are you sure to continue? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        return 0
    fi
    
    log_info "Stopping cluster..."
    ./stop-cluster.sh
    
    log_info "Cleaning data volumes..."
    docker-compose down -v
    
    log_info "Restarting cluster..."
    ./start-cluster.sh
}

# Show detailed status
show_detailed_status() {
    log_info "Showing detailed status information..."
    
    echo ""
    echo "=== Container Status ==="
    docker-compose ps
    
    echo ""
    echo "=== Network Status ==="
    docker network ls | grep hadoop || echo "hadoop network not found"
    
    echo ""
    echo "=== Port Usage Status ==="
    netstat -tlnp 2>/dev/null | grep -E "(2181|8485|9820|9870)" || echo "No related port usage found"
    
    echo ""
    echo "=== JournalNode Process Status ==="
    for i in {1..3}; do
        local container="journalnode$i"
        echo "  $container:"
        if docker exec "$container" pgrep -f "journalnode" >/dev/null 2>&1; then
            echo "    ✅ JournalNode process is running"
        else
            echo "    ❌ JournalNode process is not running"
        fi
        
        if docker exec "$container" netstat -ln 2>/dev/null | grep -q ":8485.*LISTEN"; then
            echo "    ✅ Port 8485 is listening"
        else
            echo "    ❌ Port 8485 is not listening"
        fi
    done
}

# Main menu
show_menu() {
    echo ""
    echo "Please select an operation:"
    echo "1) Check cluster status"
    echo "2) Check network connectivity"
    echo "3) Detailed JournalNode check"
    echo "4) Check ZooKeeper status"
    echo "5) Reset and restart JournalNode"
    echo "6) Show detailed status information"
    echo "7) Complete cluster reset"
    echo "8) Exit"
    echo ""
}

# Main program
main() {
    # First quickly check basic status
    if ! check_containers; then
        log_error "Basic check failed, please resolve container issues first"
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Please enter option [1-8]: " choice
        
        case $choice in
            1)
                check_containers
                ;;
            2)
                check_network
                ;;
            3)
                check_journalnodes
                ;;
            4)
                check_zookeeper
                ;;
            5)
                reset_journalnodes
                ;;
            6)
                show_detailed_status
                ;;
            7)
                full_reset
                ;;
            8)
                log_info "Exiting troubleshooting tool"
                exit 0
                ;;
            *)
                log_error "Invalid option, please enter 1-8"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Execute main program
main 