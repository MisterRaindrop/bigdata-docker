#!/bin/bash

echo "Fixing Hadoop cluster directory permissions..."

# Get all running containers
containers=(
    "namenode1"
    "namenode2"
    "journalnode1"
    "journalnode2"
    "journalnode3"
    "datanode1"
    "datanode2"
    "datanode3"
    "resourcemanager1"
    "resourcemanager2"
)

# Fix permissions for each container
for container in "${containers[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
        echo "Fixing permissions for $container..."
        
        # Create necessary directories and set permissions
        docker exec -u root $container bash -c "
            # Create Hadoop related directories
            mkdir -p /hadoop/dfs/name
            mkdir -p /hadoop/dfs/data  
            mkdir -p /hadoop/dfs/journal
            mkdir -p /opt/hadoop/data
            mkdir -p /opt/hadoop/logs
            
            # Set directory permissions
            chmod -R 755 /hadoop
            chmod -R 755 /opt/hadoop/data
            chmod -R 755 /opt/hadoop/logs
            
            # Ensure hadoop user owns these directories
            chown -R hadoop:hadoop /hadoop || true
            chown -R hadoop:hadoop /opt/hadoop/data || true
            chown -R hadoop:hadoop /opt/hadoop/logs || true
            
            # Special handling for JournalNode directories
            if [[ '$container' == journalnode* ]]; then
                mkdir -p /hadoop/dfs/journal
                chmod 755 /hadoop/dfs/journal
                chown hadoop:hadoop /hadoop/dfs/journal || true
            fi
            
            # Special handling for NameNode directories
            if [[ '$container' == namenode* ]]; then
                mkdir -p /hadoop/dfs/name
                chmod 755 /hadoop/dfs/name
                chown hadoop:hadoop /hadoop/dfs/name || true
            fi
            
            # Special handling for DataNode directories
            if [[ '$container' == datanode* ]]; then
                mkdir -p /hadoop/dfs/data
                chmod 755 /hadoop/dfs/data
                chown hadoop:hadoop /hadoop/dfs/data || true
            fi
        "
        
        echo "✅ $container permissions fixed successfully"
    else
        echo "⚠️  $container container is not running, skipping"
    fi
done

echo "✅ All container permissions fixed successfully!" 