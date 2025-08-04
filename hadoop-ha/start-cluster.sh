#!/bin/bash

# Exit on any error
set -e

echo "Starting Hadoop HA cluster..."

# Step 1: Clean up existing containers and volumes
echo "Cleaning up existing containers and volumes..."
docker-compose down -v

# Step 2: Start containers
echo "Starting containers..."
docker-compose up -d

# Step 3: Wait for containers to be ready
echo "Waiting for containers to be ready..."
sleep 30

# Step 4: Check if containers are running
echo "Checking container status..."
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Some containers failed to start"
    docker-compose ps
    exit 1
fi

# Step 5: Initialize the cluster
echo "Initializing cluster..."
chmod +x ./scripts/init-ha.sh
if ! ./scripts/init-ha.sh; then
    echo "❌ Cluster initialization failed"
    echo ""
    echo "🔧 Troubleshooting suggestions:"
    echo "1. Run troubleshooting tool: chmod +x fix-cluster.sh && ./fix-cluster.sh"
    echo "2. Check JournalNode status: docker logs journalnode1 --tail 20"
    echo "3. Check network connection: docker exec namenode1 nc -z journalnode1 8485"
    echo "4. Complete cluster reset: ./reset-cluster.sh && ./start-cluster.sh"
    echo ""
    echo "=== NameNode1 logs ==="
    docker logs namenode1 --tail 15
    echo ""
    echo "=== JournalNode1 logs ==="
    docker logs journalnode1 --tail 15
    exit 1
fi

# Step 6: Final status check
echo "Performing final status check..."
echo "Cluster status:"
docker-compose ps

echo ""
echo "✅ Hadoop HA cluster started successfully!"
echo ""
echo "Access addresses:"
echo "  NameNode1 Web UI: http://localhost:9870"
echo "  NameNode2 Web UI: http://localhost:9871"
echo "  ResourceManager1 Web UI: http://localhost:8088"
echo "  ResourceManager2 Web UI: http://localhost:8089"
echo "  DataNode1 Web UI: http://localhost:9864"
echo "  DataNode2 Web UI: http://localhost:9874"
echo "  DataNode3 Web UI: http://localhost:9884"
echo ""
echo "RPC ports:"
echo "  NameNode1 RPC: localhost:9820"
echo "  NameNode2 RPC: localhost:9821" 
echo "  DataNode1 Data: localhost:9866"
echo "  DataNode2 Data: localhost:9876"
echo "  DataNode3 Data: localhost:9886"
echo "  ResourceManager1 RPC: localhost:8030"
echo "  ResourceManager2 RPC: localhost:8031"
echo ""
echo "Test commands:"
echo "  Test Web proxy: ./test-proxy.sh"
echo "  Test RPC proxy: ./test-rpc.sh" 