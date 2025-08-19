# Hadoop HA Cluster Deployment Guide

This is a Docker-based Hadoop High Availability (HA) cluster that supports deployment on mainstream Linux distributions such as CentOS 7, Ubuntu, Debian, etc.

## 📋 System Requirements

### Hardware Requirements
- **CPU**: 2 cores or more
- **Memory**: Minimum 4GB, recommended 8GB
- **Hard Disk**: At least 10GB available space
- **Network**: Able to access Docker Hub

### Supported Operating Systems
- ✅ CentOS 7/8/Stream
- ✅ Ubuntu 18.04/20.04/22.04
- ✅ Debian 10/11
- ✅ RHEL 7/8/9
- ✅ Rocky Linux 8/9
- ✅ AlmaLinux 8/9

## 🌐 Network Configuration

This cluster is configured to use the `share-enterprise-ci` Docker network. This allows other Docker containers to access the Hadoop HA cluster services.

### Network Setup

Make sure the `share-enterprise-ci` network exists before starting the cluster:

```bash
# Check if the network exists
docker network ls | grep share-enterprise-ci

# If it doesn't exist, create it
docker network create share-enterprise-ci
```

### Connecting Other Containers

If other Docker containers need to access the Hadoop HA cluster, they must be connected to the `share-enterprise-ci` network:

```bash
# Connect an existing container to the network
docker network connect share-enterprise-ci your-container-name

# Or specify the network when running a new container
docker run --network share-enterprise-ci your-image
```

### Service Access from Other Containers

Once connected to the `share-enterprise-ci` network, other containers can access Hadoop services using the container names:

- **NameNode1**: `namenode1:9820` (RPC), `namenode1:9870` (Web UI)
- **NameNode2**: `namenode2:9820` (RPC), `namenode2:9870` (Web UI)
- **DataNode1**: `datanode1:9866` (Data transfer), `datanode1:9864` (Web UI)
- **DataNode2**: `datanode2:9866` (Data transfer), `datanode2:9864` (Web UI)
- **DataNode3**: `datanode3:9866` (Data transfer), `datanode3:9864` (Web UI)
- **ResourceManager1**: `resourcemanager1:8030` (RPC), `resourcemanager1:8088` (Web UI)
- **ResourceManager2**: `resourcemanager2:8030` (RPC), `resourcemanager2:8088` (Web UI)

### Network Verification

You can verify the network configuration using:
```bash
./check-network.sh
```

## 🚀 Environment Preparation

### 🔧 Automatic Installation (Recommended)

If you want to quickly install Docker and Docker Compose, you can use our provided automatic installation script:

```bash
# Run automatic installation script (supports CentOS, Ubuntu, Debian, etc.)
./install-docker.sh
```

This script will automatically:
- Detect your operating system type
- Install the latest versions of Docker and Docker Compose
- Configure Docker service
- Optimize system parameters
- Add current user to docker group

### 🛠️ Manual Installation

If you need to install manually or encounter automatic installation issues, please refer to the following steps:

### CentOS 7/8 System Preparation

#### 1. Update System
```bash
# CentOS 7
sudo yum update -y
sudo yum install -y epel-release

# CentOS 8/Stream
sudo dnf update -y
sudo dnf install -y epel-release
```

#### 2. Install Docker
```bash
# Remove old versions
sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

# Install dependencies
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# Add Docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER
```

#### 3. Install Docker Compose
```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Set execution permissions
sudo chmod +x /usr/local/bin/docker-compose

# Create soft link (optional)
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installation
docker-compose --version
```

### Ubuntu/Debian System Preparation

#### 1. Update System
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git
```

#### 2. Install Docker
```bash
# Remove old versions
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install dependencies
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index and install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER
```

#### 3. Install Docker Compose
```bash
# Method 1: Install using apt (Ubuntu 20.04+)
sudo apt install -y docker-compose

# Method 2: Manually install latest version
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### System Configuration Optimization

#### 1. Adjust System Parameters
```bash
# Increase file descriptor limit
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Adjust kernel parameters
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

#### 2. Configure Firewall (if enabled)
```bash
# CentOS/RHEL uses firewalld
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=9820-9821/tcp
sudo firewall-cmd --permanent --add-port=9866-9868/tcp
sudo firewall-cmd --permanent --add-port=8030-8031/tcp
sudo firewall-cmd --reload

# Ubuntu/Debian uses ufw
sudo ufw allow 80/tcp
sudo ufw allow 9820:9821/tcp
sudo ufw allow 9866:9868/tcp
sudo ufw allow 8030:8031/tcp
```

#### 3. Re-login to apply docker group permissions
```bash
# Log out and log back in, or use
newgrp docker
```

## 📦 Deploy Hadoop HA Cluster

### 1. Download Project
```bash
# Clone project
git clone <your-repository-url>
cd bigdata-docker/hadoop-ha

# Or directly download project files to hadoop-ha directory
```

### 2. Verify File Permissions
```bash
# Ensure scripts have execution permissions
chmod +x *.sh
chmod +x scripts/*.sh
```

### 3. Environment Check (Strongly Recommended)
```bash
# Run environment check script to ensure system meets deployment requirements
./check-environment.sh
```

### 4. Start Cluster
```bash
# Start Hadoop HA cluster
./start-cluster.sh
```

### 5. Wait for Cluster Startup
First startup may take 5-10 minutes because it needs to:
- Download Docker images
- Initialize ZooKeeper cluster
- Format NameNode
- Start all services

## 🌐 Access Services

### Web UI Addresses
- **NameNode1**: http://localhost/namenode1/index.html
- **NameNode2**: http://localhost/namenode2/index.html
- **YARN**: http://localhost/yarn/
- **DataNode1**: http://localhost/datanode1/
- **DataNode2**: http://localhost/datanode2/
- **DataNode3**: http://localhost/datanode3/

### RPC Ports
- **NameNode1 RPC**: localhost:9820
- **NameNode2 RPC**: localhost:9821
- **DataNode1 RPC**: localhost:9866
- **DataNode2 RPC**: localhost:9867
- **DataNode3 RPC**: localhost:9868
- **ResourceManager1 RPC**: localhost:8030
- **ResourceManager2 RPC**: localhost:8031

## 🔧 Cluster Management

### Basic Operations
```bash
# Start cluster
./start-cluster.sh

# Stop cluster
./stop-cluster.sh

# Reset cluster (clean all data)
./reset-cluster.sh

# Check cluster status
./check-status.sh

# View container status
docker-compose ps
```

### Start YARN Services (Optional)
```bash
# Start ResourceManager
docker exec -d resourcemanager1 yarn resourcemanager
docker exec -d resourcemanager2 yarn resourcemanager

# Start NodeManager (if needed)
docker exec -d datanode1 yarn nodemanager
docker exec -d datanode2 yarn nodemanager
docker exec -d datanode3 yarn nodemanager
```

## 🛠️ Troubleshooting

### Common Diagnostic Commands
```bash
# Check container status
docker ps -a

# View container logs
docker logs namenode1
docker logs journalnode1
docker logs nginx-proxy

# Check network
docker network ls
docker network inspect share-enterprise-ci

# Check port usage
sudo netstat -tlnp | grep -E "(80|9820|9821)"
# Or use ss command
sudo ss -tlnp | grep -E "(80|9820|9821)"
```

### Repair Scripts
```bash
# Fix permission issues
./fix-permissions.sh

# Fix cluster issues
./fix-cluster.sh

# Test web proxy
./test-proxy.sh

# Test RPC proxy
./test-rpc.sh
```

## 🔍 Common Problem Solutions

### Q1: Docker Cannot Start
```bash
# Check Docker service status
sudo systemctl status docker

# Start Docker service
sudo systemctl start docker

# Check Docker version
docker --version
docker-compose --version
```

### Q2: Port Conflicts
```bash
# Check port usage
sudo lsof -i :80
sudo lsof -i :9820

# Stop services using the ports
sudo systemctl stop nginx  # If there are other nginx services
```

### Q3: Permission Errors
```bash
# Check if current user is in docker group
groups $USER

# Re-add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Q4: Cannot Access Web UI
```bash
# Check nginx container status
docker ps | grep nginx

# Restart nginx container
docker restart nginx-proxy

# Check nginx configuration
docker exec nginx-proxy nginx -t
```

### Q5: NameNode Cannot Start
```bash
# View NameNode logs
docker logs namenode1 --tail 50

# Reset cluster
./reset-cluster.sh
./start-cluster.sh
```

### Q6: Network Connection Issues
```bash
# Check if share-enterprise-ci network exists
docker network ls | grep share-enterprise-ci

# Create network if it doesn't exist
docker network create share-enterprise-ci

# Check network connectivity
./check-network.sh

# Verify container network connections
docker network inspect share-enterprise-ci
```

## 🏗️ Cluster Architecture

### Service Components
- **ZooKeeper**: 3 nodes for cluster coordination
- **JournalNode**: 3 nodes for storing edit logs
- **NameNode**: 2 nodes for high availability
- **DataNode**: 3 nodes for data storage
- **ResourceManager**: 2 nodes for YARN resource management
- **Nginx**: Reverse proxy providing unified access entry

### Data Persistence
```bash
# View Docker volumes
docker volume ls | grep hadoop-ha

# Backup important data
docker run --rm -v hadoop-ha_nn1_data:/data -v $(pwd):/backup ubuntu tar czf /backup/namenode1-backup.tar.gz /data
```

## 📁 Directory Structure

```
hadoop-ha/
├── README.md              # This document
├── docker-compose.yml     # Docker Compose configuration
├── config/                # Hadoop configuration files directory
│   ├── core-site.xml      # Core configuration
│   ├── hdfs-site.xml      # HDFS configuration
│   ├── yarn-site.xml      # YARN configuration
│   ├── hadoop-env.sh      # Environment variables
│   ├── log4j.properties   # Logging configuration
│   ├── workers            # Worker nodes list
│   └── zoo.cfg            # ZooKeeper configuration
├── nginx/                 # Nginx configuration directory
│   └── nginx.conf         # Reverse proxy configuration
├── scripts/               # Initialization scripts directory
│   └── init-ha.sh         # HA cluster initialization script
├── install-docker.sh      # Docker auto-installation script
├── check-environment.sh   # Environment check script
├── start-cluster.sh       # Start cluster script
├── stop-cluster.sh        # Stop cluster script
├── reset-cluster.sh       # Reset cluster script
├── check-status.sh        # Check status script
├── fix-permissions.sh     # Fix permissions script
├── fix-cluster.sh         # Fix cluster script
├── test-proxy.sh          # Test web proxy script
├── test-rpc.sh           # Test RPC proxy script
├── start-datanodes.sh     # DataNode startup and check script
├── check-network.sh       # Network configuration check script
└── DATANODE-TROUBLESHOOTING.md  # DataNode troubleshooting guide
```

## ⚡ Performance Tuning

### System Optimization
```bash
# Adjust Docker default configuration
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF

# Restart Docker
sudo systemctl restart docker
```

### Cluster Configuration Optimization
You can modify the configuration files in the `config/` directory to optimize performance as needed.

## 🔐 Security Configuration

### Production Environment Recommendations
```bash
# 1. Change default ports
# 2. Enable Kerberos authentication
# 3. Configure SSL/TLS
# 4. Set up firewall rules
# 5. Regular data backup
```

## 📚 References

- [Apache Hadoop Official Documentation](https://hadoop.apache.org/docs/)
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 🤝 Technical Support

If you encounter problems, please troubleshoot according to the following steps:

1. Check if system requirements are met
2. Confirm Docker and Docker Compose are correctly installed
3. View container logs to locate issues
4. Run troubleshooting scripts
5. Refer to common problem solutions

---

## 📋 Quick Checklist

Before deployment, please confirm:

- [ ] System meets hardware requirements
- [ ] Docker is correctly installed and started
- [ ] Docker Compose is installed
- [ ] Current user has been added to docker group
- [ ] Necessary ports are not occupied
- [ ] Firewall rules are configured (if enabled)
- [ ] System parameters are optimized
- [ ] share-enterprise-ci network exists or can be created

After deployment, please verify:

- [ ] All containers are running normally
- [ ] Web UI is accessible
- [ ] NameNode status is normal
- [ ] HDFS reports are normal
- [ ] Network connections are normal
- [ ] share-enterprise-ci network connectivity is working
- [ ] Other containers can access Hadoop services via network 