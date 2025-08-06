# DataNode Troubleshooting Guide

## Problem Description

When you run `hdfs dfsadmin -report`, if you see the following output, it indicates that DataNode is not started properly:

```
Configured Capacity: 0 (0 B)
Present Capacity: 0 (0 B)
DFS Remaining: 0 (0 B)
DFS Used: 0 (0 B)
DFS Used%: 0.00%
```

## Solutions

### Method 1: Use Automatic Repair Script (Recommended)

We provide an automated script to check and start DataNode:

```bash
# Check and start DataNode
./start-datanodes.sh

# Check status only, do not start
./start-datanodes.sh --check-only

# Show help information
./start-datanodes.sh --help
```

### Method 2: Manual Repair

If the script cannot solve the problem, you can manually execute the following steps:

#### 1. Check Container Status
```bash
docker-compose ps
```

#### 2. Check DataNode Processes
```bash
docker exec datanode1 ps aux | grep datanode
docker exec datanode2 ps aux | grep datanode
docker exec datanode3 ps aux | grep datanode
```

#### 3. Fix Permission Issues
```bash
# Fix DataNode1 permissions
docker exec -u root datanode1 bash -c "chmod -R 755 /hadoop && chown -R hadoop:hadoop /hadoop"

# Fix DataNode2 permissions
docker exec -u root datanode2 bash -c "chmod -R 755 /hadoop && chown -R hadoop:hadoop /hadoop"

# Fix DataNode3 permissions
docker exec -u root datanode3 bash -c "chmod -R 755 /hadoop && chown -R hadoop:hadoop /hadoop"
```

#### 4. Start DataNode Processes
```bash
# Start DataNode1
docker exec -d datanode1 hdfs datanode

# Start DataNode2
docker exec -d datanode2 hdfs datanode

# Start DataNode3
docker exec -d datanode3 hdfs datanode
```

#### 5. Verify Startup Status
```bash
# Wait for startup
sleep 10

# Check processes
docker exec datanode1 ps aux | grep datanode
docker exec datanode2 ps aux | grep datanode
docker exec datanode3 ps aux | grep datanode

# Check HDFS status
docker exec namenode1 hdfs dfsadmin -report
```

## Common Issues

### 1. Permission Issues
**Symptoms**: DataNode process fails to start
**Solution**: Run permission fix commands

### 2. Containers Not Running
**Symptoms**: Script reports containers are not running
**Solution**: Start the cluster first `docker-compose up -d`

### 3. Network Connection Issues
**Symptoms**: DataNode cannot connect to NameNode
**Solution**: Check network configuration and firewall settings

### 4. Insufficient Disk Space
**Symptoms**: DataNode exits immediately after startup
**Solution**: Check disk space `df -h`

## Verify Success

When DataNode starts normally, you should see:

```
Live datanodes (3):
Name: 172.21.0.x:9866 (datanode1.hadoop-ha_hadoop-network)
Hostname: datanode1
Decommission Status : Normal
Configured Capacity: 320955904000 (298.91 GB)
...
```

## Preventive Measures

1. **Regular Checks**: Use `./start-datanodes.sh --check-only` to regularly check status
2. **Monitor Logs**: Pay attention to DataNode logs `docker logs datanode1`
3. **Backup Configuration**: Regularly backup important configuration files
4. **Test Scripts**: Verify script reliability in test environment

## Contact Support

If the problem persists, please provide the following information:
- Complete script output
- DataNode container logs
- System resource usage
- Network configuration information 