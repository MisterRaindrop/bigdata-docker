#!/bin/bash

# Exit on any error
set -e

echo "Creating required directories for Hadoop HA cluster..."

# Create base directory
mkdir -p /tmp/hadoop-ha

# Create directories for ZooKeeper
for i in {1..3}; do
    mkdir -p "/tmp/hadoop-ha/zk${i}_data"
    mkdir -p "/tmp/hadoop-ha/zk${i}_datalog"
done

# Create directories for JournalNodes
for i in {1..3}; do
    mkdir -p "/tmp/hadoop-ha/jn${i}_data"
done

# Create directories for NameNodes
for i in {1..2}; do
    mkdir -p "/tmp/hadoop-ha/nn${i}_data"
done

# Create directories for DataNodes
for i in {1..3}; do
    mkdir -p "/tmp/hadoop-ha/dn${i}_data"
done

# Set permissions
chmod -R 777 /tmp/hadoop-ha

echo "✅ All directories created successfully"
echo "Directory structure:"
ls -l /tmp/hadoop-ha