#!/bin/bash

# Exit on any error
set -e

echo "Stopping Hadoop HA Cluster..."

# Stop all containers and remove volumes
echo "Stopping all containers and cleaning up volumes..."
docker-compose down -v

# Remove any orphaned containers
echo "Removing orphaned containers..."
docker container prune -f

# Remove unused volumes
echo "Removing unused volumes..."
docker volume prune -f

echo "Hadoop HA Cluster stopped and cleaned up successfully!" 