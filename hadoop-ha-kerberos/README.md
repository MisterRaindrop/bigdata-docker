# Hadoop HA with Kerberos Deployment Guide

This is a Kerberos-enabled Hadoop High Availability (HA) deployment based on Docker Compose. It has a clean layout, supports Ubuntu and CentOS 7, and uses the external Docker network `share-enterprise-ci` so that other containers can access Hadoop services via hostnames.

## Features
- Hadoop 3 HA (NameNode×2, JournalNode×3, DataNode×3)
- YARN (ResourceManager×2) with Kerberos
- Built-in MIT Kerberos KDC container
- Clean layout: one compose file, one init script, one start script, one stop script
- Uses external network `share-enterprise-ci`; other containers can join the network to access by hostname

## Prerequisites
- Docker and Docker Compose installed (Ubuntu/CentOS 7 supported)
- Ensure external network exists:
```bash
docker network ls | grep share-enterprise-ci || docker network create share-enterprise-ci
```

## Quick Start
```bash
cd hadoop-ha-kerberos
# Start and initialize Kerberos + Hadoop HA
./start-cluster.sh

# Verify HDFS
docker exec namenode1 hdfs dfsadmin -report
```

## Kerberos Realm
- Default Realm: `EXAMPLE.COM`
- Admin password: env `KERBEROS_ADMIN_PASSWORD` (default `adminpassword`)
- Generated keytabs are stored in `./keytabs/` and mounted read-only into Hadoop containers

## Access from Other Containers
Other Docker containers must join the `share-enterprise-ci` network:
```bash
docker network connect share-enterprise-ci your-container
# Example: access NameNode1 Web UI by hostname
curl -I http://namenode1:9870
```

## Directory Structure
```
hadoop-ha-kerberos/
├── README.md
├── docker-compose.yml
├── start-cluster.sh
├── stop-cluster.sh
├── scripts/
│   └── init-kerberos.sh
├── config/
│   ├── core-site.xml
│   ├── hdfs-site.xml
│   ├── yarn-site.xml
│   ├── hadoop-env.sh
│   ├── krb5.conf
│   └── workers
└── keytabs/               # generated at runtime
```

## Notes
- Initially `dfs.ha.automatic-failover.enabled=false`. You can enable automatic failover later after securing ZooKeeper with SASL.
- Logic is focused in `scripts/init-kerberos.sh` and `start-cluster.sh` to keep the layout clean.

## Cleanup
```bash
./stop-cluster.sh
```