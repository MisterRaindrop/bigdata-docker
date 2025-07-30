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

echo "Starting Hadoop HA cluster initialization..."

# Step 1: Start ZooKeeper cluster
echo "Step 1: Starting ZooKeeper cluster..."
docker-compose up -d zookeeper1 zookeeper2 zookeeper3
for zk in zookeeper1 zookeeper2 zookeeper3; do
    wait_for_container $zk
done
echo "ZooKeeper cluster is running"

# Step 2: Start JournalNode cluster
echo "Step 2: Starting JournalNode cluster..."
docker-compose up -d journalnode1 journalnode2 journalnode3
for jn in journalnode1 journalnode2 journalnode3; do
    wait_for_container $jn
done

# Wait for JournalNode services to be ready
echo "Waiting for JournalNode services to be ready..."
for jn in journalnode1 journalnode2 journalnode3; do
    echo "Checking $jn connectivity..."
    max_attempts=30
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker exec $jn nc -z localhost 8485; then
            echo "$jn is ready"
            break
        else
            echo "Attempt $attempt: $jn is not ready yet..."
            if [ $attempt -eq $max_attempts ]; then
                echo "Error: $jn failed to become ready"
                exit 1
            fi
            sleep 2
            attempt=$((attempt + 1))
        fi
    done
done
echo "JournalNode cluster is running and ready"

# Step 2.5: Initialize JournalNode cluster
echo "Step 2.5: Initializing JournalNode cluster..."
# The JournalNode cluster doesn't need explicit initialization like ZooKeeper
# It will create the necessary directories when the first NameNode connects

# Step 3: Start and format first NameNode
echo "Step 3: Starting first NameNode..."
docker-compose up -d namenode1
wait_for_container namenode1

echo "Formatting ZooKeeper..."
max_attempts=3
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker exec namenode1 hdfs zkfc -formatZK -force; then
        echo "Successfully formatted ZooKeeper"
        break
    else
        echo "Failed to format ZooKeeper (attempt $attempt of $max_attempts)"
        if [ $attempt -eq $max_attempts ]; then
            echo "Error: Failed to format ZooKeeper after $max_attempts attempts"
            exit 1
        fi
        sleep 10
        attempt=$((attempt + 1))
    fi
done

echo "Formatting NameNode..."
max_attempts=3
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker exec namenode1 hdfs namenode -format -force; then
        echo "Successfully formatted NameNode"
        break
    else
        echo "Failed to format NameNode (attempt $attempt of $max_attempts)"
        if [ $attempt -eq $max_attempts ]; then
            echo "Error: Failed to format NameNode after $max_attempts attempts"
            exit 1
        fi
        sleep 10
        attempt=$((attempt + 1))
    fi
done

# Step 4: Start NameNode and ZKFC services on namenode1
echo "Step 4: Starting NameNode and ZKFC services on namenode1..."
docker exec namenode1 /bin/bash -c "/opt/hadoop/sbin/hadoop-daemon.sh start zkfc"
docker exec namenode1 /bin/bash -c "nohup hdfs namenode > /tmp/namenode.log 2>&1 &"
sleep 10  # Wait for services to start

# Step 5: Start second NameNode and synchronize metadata
echo "Step 5: Starting second NameNode..."
docker-compose up -d namenode2
wait_for_container namenode2

echo "Bootstrapping standby NameNode..."
max_attempts=3
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker exec namenode2 hdfs namenode -bootstrapStandby -force; then
        echo "Successfully bootstrapped standby NameNode"
        break
    else
        echo "Failed to bootstrap standby NameNode (attempt $attempt of $max_attempts)"
        if [ $attempt -eq $max_attempts ]; then
            echo "Error: Failed to bootstrap standby NameNode after $max_attempts attempts"
            exit 1
        fi
        sleep 10
        attempt=$((attempt + 1))
    fi
done

echo "Starting NameNode and ZKFC services on namenode2..."
docker exec namenode2 /bin/bash -c "/opt/hadoop/sbin/hadoop-daemon.sh start zkfc"
docker exec namenode2 /bin/bash -c "nohup hdfs namenode > /tmp/namenode.log 2>&1 &"
sleep 10  # Wait for services to start

# Step 6: Start remaining services
echo "Step 6: Starting remaining services..."
docker-compose up -d

# Step 7: Wait for all services to start
echo "Step 7: Waiting for all services to start..."
sleep 30

# Step 8: Verify cluster status
echo "Verifying cluster status..."

echo "NameNode status:"
if ! docker exec namenode1 hdfs haadmin -getServiceState nn1; then
    echo "Warning: Unable to get nn1 status"
fi

if ! docker exec namenode2 hdfs haadmin -getServiceState nn2; then
    echo "Warning: Unable to get nn2 status"
fi

echo "DataNode status:"
if ! docker exec namenode1 hdfs dfsadmin -report | grep "Live datanodes"; then
    echo "Warning: Unable to get DataNode status"
fi

echo "Hadoop HA cluster initialization completed!"
echo "Access URLs:"
echo "  NameNode1 Web UI: http://localhost:9870"
echo "  NameNode2 Web UI: http://localhost:9871"
echo "  YARN Web UI: http://localhost:8088"