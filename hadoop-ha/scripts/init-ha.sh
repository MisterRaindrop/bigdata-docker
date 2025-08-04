#!/bin/bash

# Exit on any error
set -e

echo "Starting Hadoop HA cluster initialization..."

# Function to wait for container to be ready
wait_for_container() {
    local container_name=$1
    local max_attempts=30
    local attempt=1
    
    echo "Waiting for $container_name container to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if docker exec $container_name echo "Container is ready" > /dev/null 2>&1; then
            echo "✅ $container_name container is ready"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: $container_name not ready yet..."
        sleep 5
        attempt=$((attempt + 1))
    done
    echo "❌ $container_name container not ready after $max_attempts attempts"
    return 1
}

# Function to check if service is running on port
check_service_port() {
    local container_name=$1
    local port=$2
    local max_attempts=20
    local attempt=1
    
    echo "Checking port $port on $container_name..."
    while [ $attempt -le $max_attempts ]; do
        # Use nc from namenode1 to test connection to specified container port
        if docker exec namenode1 nc -z $container_name $port 2>/dev/null; then
            echo "✅ $container_name port $port is ready"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: $container_name port $port not ready yet..."
        sleep 3
        attempt=$((attempt + 1))
    done
    echo "❌ $container_name port $port not ready after $max_attempts attempts"
    return 1
}

# Step 1: Wait for all containers to start
echo "=== Step 1: Wait for all containers to start ==="
containers=(
    "zookeeper1"
    "zookeeper2" 
    "zookeeper3"
    "journalnode1"
    "journalnode2"
    "journalnode3"
    "namenode1"
    "namenode2"
)

for container in "${containers[@]}"; do
    wait_for_container "$container"
done

# Step 2: Wait for ZooKeeper cluster to start
echo "=== Step 2: Wait for ZooKeeper cluster to start ==="
sleep 15
echo "✅ ZooKeeper cluster started successfully"

# Step 3: Initialize HA nodes in ZooKeeper
echo "=== Step 3: Initialize ZooKeeper HA nodes ==="
echo "Formatting ZooKeeper..."
docker exec zookeeper1 zkCli.sh -server zookeeper1:2181 create /hadoop-ha "" 2>/dev/null || echo "ZooKeeper node already exists"

# Step 4: Fix permissions and start JournalNode
echo "=== Step 4: Fix permissions and start JournalNode ==="

# Fix permissions first
echo "Fixing JournalNode directory permissions..."
for jn in journalnode1 journalnode2 journalnode3; do
    docker exec -u root $jn bash -c "
        mkdir -p /hadoop/dfs/journal
        chmod -R 755 /hadoop
        chown -R hadoop:hadoop /hadoop
    "
done

# Start JournalNode services
echo "Starting JournalNode processes..."
docker exec -d journalnode1 hdfs journalnode
docker exec -d journalnode2 hdfs journalnode
docker exec -d journalnode3 hdfs journalnode

# Wait for JournalNode services to start and listen on ports
echo "Waiting for JournalNode services to be ready..."
for jn in journalnode1 journalnode2 journalnode3; do
    if ! check_service_port "$jn" 8485; then
        echo "❌ $jn startup failed, checking logs..."
        docker logs "$jn" --tail 20
        exit 1
    fi
done

echo "✅ All JournalNodes started successfully"

# Step 5: Clean up NameNode environment
echo "=== Step 5: Clean up NameNode environment ==="

# Stop any running NameNode processes
echo "Stopping existing NameNode processes..."
docker exec namenode1 pkill -f "namenode" || echo "namenode1 no running processes"
docker exec namenode2 pkill -f "namenode" || echo "namenode2 no running processes"

# Clean up PID files
echo "Cleaning up PID files..."
docker exec namenode1 rm -f /tmp/hadoop-*.pid || echo "namenode1 no PID files"
docker exec namenode2 rm -f /tmp/hadoop-*.pid || echo "namenode2 no PID files"

# Fix NameNode permissions and create directories
echo "Fixing NameNode permissions and creating necessary directories..."
for nn in namenode1 namenode2; do
    docker exec -u root $nn bash -c "
        mkdir -p /hadoop/dfs/name
        chmod -R 755 /hadoop
        chown -R hadoop:hadoop /hadoop
    "
done

# Step 6: Format ZK
echo "=== Step 6: Format ZK ==="
docker exec namenode1 hdfs zkfc -formatZK -force

# Step 7: Format NameNode1
echo "=== Step 7: Format NameNode1 ==="
for attempt in {1..3}; do
    echo "Attempting to format NameNode1 (attempt $attempt/3)..."
    
    if docker exec namenode1 hdfs namenode -format -force -nonInteractive; then
        echo "✅ NameNode1 formatted successfully"
        break
    else
        echo "❌ NameNode1 formatting failed (attempt $attempt/3)"
        if [ $attempt -eq 3 ]; then
            echo "❌ NameNode1 formatting failed finally"
            docker logs namenode1 --tail 30
            exit 1
        fi
        sleep 10
    fi
done

# Step 8: Start ZKFC
echo "=== Step 8: Start ZKFC ==="
docker exec -d namenode1 hdfs zkfc
docker exec -d namenode2 hdfs zkfc

# Step 9: Start NameNode1
echo "=== Step 9: Start NameNode1 ==="
docker exec -d namenode1 hdfs namenode

# Wait for NameNode1 to start
sleep 25
echo "✅ NameNode1 started successfully"

# Step 10: Format NameNode2
echo "=== Step 10: Format NameNode2 ==="
for attempt in {1..3}; do
    echo "Attempting to format NameNode2 (attempt $attempt/3)..."
    
    if docker exec namenode2 hdfs namenode -bootstrapStandby -force -nonInteractive; then
        echo "✅ NameNode2 formatted successfully"
        break
    else
        echo "❌ NameNode2 formatting failed (attempt $attempt/3)"
        if [ $attempt -eq 3 ]; then
            echo "❌ NameNode2 formatting failed finally"
            docker logs namenode2 --tail 30
            exit 1
        fi
        sleep 10
    fi
done

# Step 11: Start NameNode2
echo "=== Step 11: Start NameNode2 ==="
docker exec -d namenode2 hdfs namenode

# Wait for NameNode2 to start
sleep 25
echo "✅ NameNode2 started successfully"

# Step 12: Start DataNode
echo "=== Step 12: Start DataNode ==="
docker exec -d datanode1 hdfs datanode
docker exec -d datanode2 hdfs datanode  
docker exec -d datanode3 hdfs datanode

# Step 13: Start ResourceManager
echo "=== Step 13: Start ResourceManager ==="
docker exec -d resourcemanager1 yarn resourcemanager
docker exec -d resourcemanager2 yarn resourcemanager

# Step 14: Wait for all services to start
echo "=== Step 14: Wait for all services to start ==="
sleep 30

# Step 15: Verify cluster status
echo "=== Step 15: Verify cluster status ==="
echo "Checking NameNode status..."
docker exec namenode1 hdfs haadmin -getServiceState nn1 || echo "NameNode1 status check failed"
docker exec namenode2 hdfs haadmin -getServiceState nn2 || echo "NameNode2 status check failed"

echo "Checking HDFS report..."
docker exec namenode1 hdfs dfsadmin -report || echo "HDFS report retrieval failed"

echo "✅ Hadoop HA cluster initialization completed!"
echo "Cluster access information:"
echo "  NameNode1 Web UI: http://localhost:9870"
echo "  NameNode2 Web UI: http://localhost:9871"
echo "  ResourceManager1 Web UI: http://localhost:8088"
echo "  ResourceManager2 Web UI: http://localhost:8089"