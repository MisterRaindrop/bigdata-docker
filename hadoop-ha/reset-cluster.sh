#!/bin/bash

echo "Resetting Hadoop cluster..."

echo "1. Stopping all containers..."
docker-compose down

echo "2. Cleaning all volumes..."
docker volume prune -f

echo "3. Cleaning networks..."
docker network prune -f

echo "4. Cleaning unused images..."
docker image prune -f

echo "5. Restarting cluster..."
./start-cluster.sh

echo "✅ Cluster reset completed" 