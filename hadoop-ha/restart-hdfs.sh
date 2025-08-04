#!/bin/bash

# HDFS cluster restart script

echo "Restarting HDFS cluster..."

# Stop all HDFS services
echo "Stopping DataNode services..."
docker exec datanode1 pkill -f datanode || true
docker exec datanode2 pkill -f datanode || true  
docker exec datanode3 pkill -f datanode || true

docker exec namenode1 pkill -f namenode || true
docker exec namenode2 pkill -f namenode || true

echo "Stopping JournalNode services..."
docker exec journalnode1 pkill -f journalnode || true
docker exec journalnode2 pkill -f journalnode || true
docker exec journalnode3 pkill -f journalnode || true

sleep 5

# Start JournalNode
echo "Starting JournalNode services..."
docker exec journalnode1 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec journalnode2 /opt/hadoop/bin/hdfs --daemon start journalnode  
docker exec journalnode3 /opt/hadoop/bin/hdfs --daemon start journalnode

sleep 5

# Start NameNode
echo "Starting NameNode services..."
docker exec namenode1 /opt/hadoop/bin/hdfs --daemon start namenode
docker exec namenode2 /opt/hadoop/bin/hdfs --daemon start namenode

sleep 10

# Set namenode1 as active
echo "Setting namenode1 as active state..."
echo "Y" | docker exec -i namenode1 hdfs haadmin -transitionToActive nn1 --forcemanual

sleep 5

# Start DataNode
echo "Starting DataNode services..."
docker exec datanode1 /opt/hadoop/bin/hdfs --daemon start datanode
docker exec datanode2 /opt/hadoop/bin/hdfs --daemon start datanode
docker exec datanode3 /opt/hadoop/bin/hdfs --daemon start datanode

sleep 10

# Check cluster status
echo "Checking cluster status..."
docker exec namenode1 hdfs haadmin -getServiceState nn1
docker exec namenode2 hdfs haadmin -getServiceState nn2
docker exec namenode1 hdfs dfsadmin -report

echo "HDFS cluster restart completed!"