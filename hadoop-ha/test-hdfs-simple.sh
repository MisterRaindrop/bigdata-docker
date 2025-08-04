#!/bin/bash

echo "=== Testing HDFS Basic Operations ==="

# Stop all NameNode processes
docker exec namenode1 pkill -f namenode || true
docker exec namenode2 pkill -f namenode || true

sleep 3

# Start namenode1
echo "Starting namenode1..."
docker exec namenode1 /opt/hadoop/bin/hdfs --daemon start namenode

sleep 10

# Check namenode1 status
echo "Checking namenode1 status..."
docker exec namenode1 hdfs haadmin -getServiceState nn1

# Now test basic HDFS operations
echo "=== Starting HDFS Basic Operations Test ==="

# 1. List root directory
echo "1. Listing HDFS root directory:"
docker exec namenode1 hdfs dfs -ls /

# 2. Create test directory
echo "2. Creating test directory /test:"
docker exec namenode1 hdfs dfs -mkdir -p /test

# 3. Create test file
echo "3. Creating local test file and uploading to HDFS:"
docker exec namenode1 bash -c 'echo "Hello HDFS World!" > /tmp/test.txt'
docker exec namenode1 hdfs dfs -put /tmp/test.txt /test/

# 4. List test directory
echo "4. Listing /test directory:"
docker exec namenode1 hdfs dfs -ls /test

# 5. Read file content
echo "5. Reading file content:"
docker exec namenode1 hdfs dfs -cat /test/test.txt

# 6. Download file
echo "6. Downloading file from HDFS:"
docker exec namenode1 hdfs dfs -get /test/test.txt /tmp/downloaded.txt
docker exec namenode1 cat /tmp/downloaded.txt

echo "=== HDFS Test Completed ==="