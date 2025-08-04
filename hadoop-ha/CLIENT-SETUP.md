# Hadoop HA Client Configuration Guide

## Problem Description
When clients access HDFS, they encounter the error `Got error, status=ERROR, status message , ack with firstBadLink as 172.18.0.8:9866`. This happens because the client receives the Docker internal IP address of DataNodes, which cannot be accessed externally.

## Solutions

### Solution 1: Add hostname mapping (Recommended)

1. **Run the client setup script (requires sudo privileges)**:
```bash
sudo ./setup-client.sh
```

2. **Or manually add to /etc/hosts**:
```bash
echo "127.0.0.1 datanode1" | sudo tee -a /etc/hosts
echo "127.0.0.1 datanode2" | sudo tee -a /etc/hosts  
echo "127.0.0.1 datanode3" | sudo tee -a /etc/hosts
```

3. **Use client configuration**:
```bash
export HADOOP_CONF_DIR=$(pwd)/config
hdfs dfs -put hadoop /test/
```

### Solution 2: Use dedicated client configuration files

1. **Copy configuration files to client**:
```bash
# Create client configuration directory
mkdir -p ~/hadoop-client-config

# Copy configuration files
cp config/core-site-client.xml ~/hadoop-client-config/core-site.xml
cp config/hdfs-site-client.xml ~/hadoop-client-config/hdfs-site.xml
```

2. **Use client configuration**:
```bash
export HADOOP_CONF_DIR=~/hadoop-client-config
hdfs dfs -put hadoop /test/
```

### Solution 3: Directly specify NameNode address

If you only need basic HDFS operations, you can directly specify the NameNode address:
```bash
hdfs dfs -fs hdfs://localhost:9820 -put hadoop /test/
```

## Verify Connection

```bash
# Check cluster status
hdfs dfsadmin -report

# List HDFS files
hdfs dfs -ls /

# Test upload
echo "Hello HDFS" > test.txt
hdfs dfs -put test.txt /test.txt

# Test download  
hdfs dfs -get /test.txt downloaded.txt
```

## Cluster Access Addresses

- **NameNode1 Web UI**: http://localhost:9870
- **NameNode2 Web UI**: http://localhost:9871  
- **NameNode1 RPC**: localhost:9820
- **NameNode2 RPC**: localhost:9821
- **DataNode1 Web UI**: http://localhost:9864
- **DataNode2 Web UI**: http://localhost:9874
- **DataNode3 Web UI**: http://localhost:9884

## Troubleshooting

If connection issues persist:

1. **Check if ports are open**:
```bash
telnet localhost 9820
telnet localhost 9866
```

2. **Check DataNode status**:
```bash
hdfs dfsadmin -report
```

3. **View NameNode logs**:
```bash
docker logs namenode1 --tail 50
```

4. **View DataNode logs**:
```bash
docker logs datanode1 --tail 50
```