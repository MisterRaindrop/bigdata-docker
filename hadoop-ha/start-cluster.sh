#!/bin/bash

# Exit on any error
set -e

# Function to check if a container is running
check_container() {
    local container_name=$1
    local status=$(docker inspect -f '{{.State.Status}}' $container_name 2>/dev/null || echo "not_found")
    if [ "$status" != "running" ]; then
        return 1
    fi
    return 0
}

# Function to wait for container to be healthy
wait_for_container() {
    local container_name=$1
    local max_attempts=30
    local attempt=1
    
    echo "Waiting for $container_name to start..."
    while ! check_container "$container_name"; do
        if [ $attempt -gt $max_attempts ]; then
            echo "Error: Container $container_name failed to start"
            return 1
        fi
        echo "Attempt $attempt: $container_name is not ready yet..."
        sleep 5
        attempt=$((attempt + 1))
    done
    echo "$container_name is running"
    return 0
}

echo "Starting Hadoop HA Cluster..."

# Step 1: Clean up existing containers and volumes
echo "Cleaning up existing containers and volumes..."
docker-compose down -v

# Step 2: Initialize the cluster
echo "Initializing the cluster..."
./scripts/init-ha.sh

# Step 3: Verify all containers are running
echo "Verifying all containers..."
containers=(
    "zookeeper1"
    "zookeeper2"
    "zookeeper3"
    "journalnode1"
    "journalnode2"
    "journalnode3"
    "namenode1"
    "namenode2"
    "datanode1"
    "datanode2"
    "datanode3"
    "resourcemanager1"
    "resourcemanager2"
)

for container in "${containers[@]}"; do
    wait_for_container "$container"
done

# Step 4: Final status check
echo "Performing final status check..."
echo "Cluster Status:"
docker-compose ps

echo "Hadoop HA Cluster is ready!"
echo "Access URLs:"
echo "  NameNode1 Web UI: http://localhost:9870"
echo "  NameNode2 Web UI: http://localhost:9871"
echo "  YARN Web UI: http://localhost:8088" 