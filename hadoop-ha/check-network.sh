#!/bin/bash

echo "🔍 Checking share-enterprise-ci network configuration..."

# Check if network exists
echo "1. Checking if share-enterprise-ci network exists..."
if docker network ls | grep -q "share-enterprise-ci"; then
    echo "✅ share-enterprise-ci network exists"
    docker network ls | grep "share-enterprise-ci"
else
    echo "❌ share-enterprise-ci network does not exist"
    echo "Please ensure the network is created: docker network create share-enterprise-ci"
    exit 1
fi

echo ""
echo "2. Checking network details..."
docker network inspect share-enterprise-ci

echo ""
echo "3. Checking if containers are connected to the correct network..."
if docker-compose ps | grep -q "Up"; then
    echo "Running containers:"
    docker-compose ps
    echo ""
    echo "Container network connections:"
    for container in $(docker-compose ps -q); do
        echo "Network for container $container:"
        docker inspect $container | grep -A 10 "Networks"
    done
else
    echo "⚠️  No running containers, please start the cluster first: ./start-cluster.sh"
fi

echo ""
echo "4. Testing network connectivity..."
if docker-compose ps | grep -q "Up"; then
    echo "Testing connection from namenode1 to journalnode1..."
    if docker exec namenode1 nc -z journalnode1 8485 2>/dev/null; then
        echo "✅ namenode1 can connect to journalnode1:8485"
    else
        echo "❌ namenode1 cannot connect to journalnode1:8485"
    fi
    
    echo "Testing connection from namenode1 to zookeeper1..."
    if docker exec namenode1 nc -z zookeeper1 2181 2>/dev/null; then
        echo "✅ namenode1 can connect to zookeeper1:2181"
    else
        echo "❌ namenode1 cannot connect to zookeeper1:2181"
    fi
else
    echo "⚠️  Cannot test connectivity, containers are not running"
fi

echo ""
echo "✅ Network check completed" 