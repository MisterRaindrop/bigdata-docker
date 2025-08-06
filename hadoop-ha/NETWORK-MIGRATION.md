# Network Configuration Migration Guide

## Overview

The Hadoop HA cluster network configuration has been migrated from the custom `hadoop-network` to the existing `share-enterprise-ci` network.

## Modified Files

### 1. docker-compose.yml
- Changed network configuration from `driver: bridge` to `external: true`
- Specified network name as `share-enterprise-ci`

### 2. check-status.sh
- Updated network status check to now check `share-enterprise-ci` network

### 3. fix-cluster.sh
- Updated network existence check
- Updated network status display

### 4. reset-cluster.sh
- Modified network cleanup logic to protect `share-enterprise-ci` network from being cleaned up

### 5. New Files
- `check-network.sh`: Script specifically for checking network configuration

## Usage Steps

### 1. Ensure Network Exists
```bash
# Check if network exists
docker network ls | grep share-enterprise-ci

# If it doesn't exist, create the network
docker network create share-enterprise-ci
```

### 2. Verify Network Configuration
```bash
# Run network check script
./check-network.sh
```

### 3. Start Cluster
```bash
# Start the cluster
./start-cluster.sh
```

### 4. Check Status
```bash
# Check cluster status
./check-status.sh
```

## Important Notes

1. **Network Dependency**: The cluster now depends on the external `share-enterprise-ci` network. Ensure this network exists before starting the cluster.

2. **Network Cleanup**: The `reset-cluster.sh` script has been modified to not clean up the `share-enterprise-ci` network.

3. **Connectivity Testing**: Use `./check-network.sh` to test network connectivity between containers.

4. **Troubleshooting**: If you encounter network issues, you can run `./fix-cluster.sh` for diagnosis and repair.

## Rollback Plan

If you need to rollback to the original network configuration:

1. Modify the network configuration in `docker-compose.yml`:
```yaml
networks:
  hadoop-network:
    driver: bridge
```

2. Restore network name references in related script files.

3. Restart the cluster. 