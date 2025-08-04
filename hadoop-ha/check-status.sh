#!/bin/bash

echo "Checking container status..."

# Check all container status
echo "=== Container Status ==="
docker-compose ps

echo ""
echo "=== Container Logs ==="

# Check NameNode container logs
echo "NameNode1 logs:"
docker logs namenode1 --tail 20

echo ""
echo "NameNode2 logs:"
docker logs namenode2 --tail 20

echo ""
echo "=== Network Status ==="
docker network ls | grep hadoop

echo ""
echo "=== Port Usage ==="
netstat -tlnp | grep -E "(9820|9821|9866|9867|9868|8030|8031)" || echo "No related ports found" 