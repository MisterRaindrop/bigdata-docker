# Hadoop HA Cluster Docker Deployment

## Project Introduction

This is a Docker-based Hadoop High Availability (HA) cluster deployment solution that provides unified Web UI and RPC access through Nginx proxy. This project provides a complete Hadoop ecosystem including HDFS and YARN high availability configuration.

## Architecture Features

- ✅ **High Availability Design**: Both NameNode and ResourceManager are configured with HA
- ✅ **Containerized Deployment**: Based on Docker Compose, one-click startup
- ✅ **Unified Proxy Access**: Access all Web UI and RPC ports through Nginx proxy
- ✅ **Automatic Initialization**: Provides complete cluster initialization scripts
- ✅ **Testing Tools**: Built-in Web and RPC connection testing scripts

## Cluster Architecture

### Service Components

| Component | Node Count | Port Mapping | Function |
|-----------|------------|--------------|----------|
| **ZooKeeper** | 3 nodes | 2181 | Coordination service, supports NameNode failover |
| **JournalNode** | 3 nodes | 8485 | Shared storage, synchronizes NameNode edit logs |
| **NameNode** | 2 nodes (HA) | 9820(RPC), 9870(Web) | HDFS metadata management |
| **DataNode** | 3 nodes | 9866(RPC), 9864(Web) | HDFS data storage |
| **ResourceManager** | 2 nodes (HA) | 8030(RPC), 8088(Web) | YARN resource management |
| **Nginx** | 1 node | 80(Web), 9820-9868(RPC) | Reverse proxy |

### Proxy Access Addresses

#### Web UI Access
- **NameNode1**: http://localhost/namenode1/
- **NameNode2**: http://localhost/namenode2/
- **YARN**: http://localhost/yarn/
- **DataNode1**: http://localhost/datanode1/
- **DataNode2**: http://localhost/datanode2/
- **DataNode3**: http://localhost/datanode3/

#### RPC Port Access
- **NameNode1 RPC**: localhost:9820
- **NameNode2 RPC**: localhost:9821
- **DataNode1 RPC**: localhost:9866
- **DataNode2 RPC**: localhost:9867
- **DataNode3 RPC**: localhost:9868
- **ResourceManager1 RPC**: localhost:8030
- **ResourceManager2 RPC**: localhost:8031

## Quick Start

### Environment Requirements

- Docker 20.10+
- Docker Compose 2.0+
- At least 8GB available memory
- At least 20GB available disk space

### One-Click Startup

```bash
cd hadoop-ha
chmod +x start-cluster.sh
./start-cluster.sh
```

The startup script will automatically complete the following operations:
1. Clean up existing containers and volumes
2. Start all service containers
3. Wait for services to be ready
4. Initialize Hadoop HA cluster
5. Start all Hadoop services
6. Verify cluster status

### Test Cluster

#### Test Web UI Access
```bash
chmod +x test-proxy.sh
./test-proxy.sh
```

#### Test RPC Port Access
```bash
chmod +x test-rpc.sh
./test-rpc.sh
```

## Usage Guide

### Cluster Management Commands

#### Check Cluster Status
```bash
# Check container status
docker-compose ps

# Check cluster status script
chmod +x check-status.sh
./check-status.sh
```

#### Stop Cluster
```bash
chmod +x stop-cluster.sh
./stop-cluster.sh
```

#### Reset Cluster (Clean all data)
```bash
chmod +x reset-cluster.sh
./reset-cluster.sh
```

### Simplified Deployment

If you only need to test basic functionality, you can use the simplified version:

```bash
chmod +x start-simple.sh
./start-simple.sh
```

Simplified version features:
- Fewer service nodes
- Faster startup time
- Suitable for development and testing

## Troubleshooting

### Troubleshooting Tools

#### Automated Troubleshooting and Repair
```bash
chmod +x fix-cluster.sh
./fix-cluster.sh
```

This tool provides interactive troubleshooting functionality:
- Check container status and network connections
- Detailed diagnosis of JournalNode and ZooKeeper status
- Automatically restart failed services
- One-click reset of entire cluster

#### Debug Mode

Enable debug mode to view detailed logs:
```bash
chmod +x debug-cluster.sh
./debug-cluster.sh
```

### Common Issues and Solutions

#### 1. JournalNode Connection Failure
**Error Message**: `java.net.ConnectException: Connection refused` to JournalNode

**Solution**:
```bash
# Use troubleshooting tool
./fix-cluster.sh
# Select option 3: Detailed JournalNode check
# Then select option 5: Reset and restart JournalNode
```

#### 2. Container Startup Failure
**Symptoms**: Containers cannot start normally or restart frequently

**Solution**:
- Check Docker resources: Ensure sufficient memory (8GB+) and disk space (20GB+)
- View container logs: `docker logs <container_name>`
- Reset cluster: `./reset-cluster.sh`

#### 3. NameNode Format Failure
**Error Message**: Error during NameNode formatting process

**Solution**:
```bash
# Complete reset
./fix-cluster.sh
# Select option 7: Complete cluster reset
```

#### 4. Web UI Unreachable
**Symptoms**: Cannot access Hadoop Web interface through browser

**Solution**:
- Check nginx proxy: `docker logs nginx-proxy`
- Confirm service status: `./check-status.sh`
- Test proxy: `./test-proxy.sh`

#### 5. RPC Connection Failure
**Symptoms**: Clients cannot connect to Hadoop RPC ports

**Solution**:
- Test RPC ports: `./test-rpc.sh`
- Check port mappings: `docker-compose ps`
- Verify nginx configuration: `./fix-cluster.sh` → option 2

### Log Viewing

```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker logs namenode1 -f
docker logs nginx-proxy -f
```

## Development and Testing

### Java RPC Client Testing

The project includes Java RPC client testing programs:

```bash
# Compile and run RPC tests
chmod +x run-rpc-test.sh
./run-rpc-test.sh
```

### Python RPC Testing

Also provides Python version of simple RPC testing:

```bash
python3 test-rpc-simple.py
```

## Configuration Guide

### Core Configuration Files

- `config/core-site.xml`: Hadoop core configuration
- `config/hdfs-site.xml`: HDFS and HA configuration
- `config/yarn-site.xml`: YARN configuration
- `nginx/nginx.conf`: Nginx proxy configuration

### Custom Configuration

1. **Modify cluster name**: Edit `mycluster` in configuration files
2. **Adjust replication factor**: Modify `dfs.replication` in `hdfs-site.xml`
3. **Port mapping**: Modify port configuration in `docker-compose.yml`

## Production Environment Considerations

1. **Security Configuration**: Enable Kerberos authentication and SSL encryption
2. **Resource Limits**: Set appropriate CPU and memory limits for containers
3. **Data Persistence**: Use external storage volumes to ensure data security
4. **Monitoring and Alerting**: Integrate Prometheus/Grafana monitoring
5. **Backup Strategy**: Regularly backup HDFS data and configuration

## License

MIT License

## Contributing

Welcome to submit Issues and Pull Requests to improve this project!
