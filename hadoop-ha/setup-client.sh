#!/bin/bash

echo "=== Setting up Hadoop Client Environment ==="

# Check if running as root user
if [ "$EUID" -eq 0 ]; then
    echo "Root user detected, will modify system hosts file"
    HOSTS_FILE="/etc/hosts"
else
    echo "Non-root user, please manually add the following content to /etc/hosts file:"
    echo "# Hadoop HA DataNodes"
    echo "127.0.0.1 datanode1"
    echo "127.0.0.1 datanode2" 
    echo "127.0.0.1 datanode3"
    echo ""
    echo "Or run this script with sudo"
    exit 1
fi

# Backup hosts file
cp $HOSTS_FILE $HOSTS_FILE.backup.$(date +%Y%m%d_%H%M%S)

# Remove previous Hadoop configuration (if exists)
sed -i '/# Hadoop HA DataNodes/,/^$/d' $HOSTS_FILE

# Add DataNode hostname mapping
echo "" >> $HOSTS_FILE
echo "# Hadoop HA DataNodes" >> $HOSTS_FILE
echo "127.0.0.1 datanode1" >> $HOSTS_FILE
echo "127.0.0.1 datanode2" >> $HOSTS_FILE
echo "127.0.0.1 datanode3" >> $HOSTS_FILE

echo "✅ DataNode hostname mapping added to $HOSTS_FILE"
echo ""
echo "Now you can use the following configuration:"
echo "  export HADOOP_CONF_DIR=$(pwd)/config"
echo "  hdfs dfs -put hadoop /test/"
echo ""
echo "Test connection:"
echo "  hdfs dfsadmin -report"