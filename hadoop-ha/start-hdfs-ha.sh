#!/bin/bash

echo "=== Starting HDFS HA Cluster ==="

# Stop all services
echo "Stopping all services..."
docker exec namenode1 pkill -f namenode || true
docker exec namenode2 pkill -f namenode || true
docker exec datanode1 pkill -f datanode || true
docker exec datanode2 pkill -f datanode || true
docker exec datanode3 pkill -f datanode || true
docker exec journalnode1 pkill -f journalnode || true
docker exec journalnode2 pkill -f journalnode || true
docker exec journalnode3 pkill -f journalnode || true

sleep 5

# Ensure data directory permissions are correct
echo "Setting directory permissions..."
for container in namenode1 namenode2 datanode1 datanode2 datanode3 journalnode1 journalnode2 journalnode3; do
    docker exec -u root $container mkdir -p /hadoop/dfs/{name,data,journal}
    docker exec -u root $container chown -R hadoop:hadoop /hadoop
done

# Start JournalNode
echo "Starting JournalNode..."
for jn in journalnode1 journalnode2 journalnode3; do
    docker exec $jn /opt/hadoop/bin/hdfs --daemon start journalnode
done

sleep 10

# Format namenode1
echo "Formatting namenode1..."
docker exec namenode1 hdfs namenode -format -force

# Start namenode1
echo "Starting namenode1..."
docker exec namenode1 /opt/hadoop/bin/hdfs --daemon start namenode

sleep 10

# Format ZK
echo "Formatting ZK..."
docker exec namenode1 hdfs zkfc -formatZK -force

# Start ZKFC
echo "Starting ZKFC..."
docker exec namenode1 /opt/hadoop/bin/hdfs --daemon start zkfc
docker exec namenode2 /opt/hadoop/bin/hdfs --daemon start zkfc

sleep 5

# Start namenode2
echo "Starting namenode2..."
docker exec namenode2 hdfs namenode -bootstrapStandby -force
docker exec namenode2 /opt/hadoop/bin/hdfs --daemon start namenode

sleep 10

# Start DataNode
echo "Starting DataNode..."
for dn in datanode1 datanode2 datanode3; do
    docker exec $dn /opt/hadoop/bin/hdfs --daemon start datanode
done

sleep 10

# Check cluster status
echo "Checking cluster status..."
docker exec namenode1 hdfs haadmin -getServiceState nn1
docker exec namenode2 hdfs haadmin -getServiceState nn2
docker exec namenode1 hdfs dfsadmin -report

echo "=== HDFS HA Cluster Started Successfully ==="