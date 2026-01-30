# Lakehouse Single Cluster

A complete data lakehouse environment in Docker for development and testing.

## What's Included

| Component | Description |
|-----------|-------------|
| **Hadoop HDFS** | Distributed file system (NameNode + DataNode) |
| **Hive** | Metastore + HiveServer2 for SQL queries |
| **Spark 3.3** | Master, Worker, History Server with Iceberg/Hudi support |
| **MinIO** | S3-compatible object storage |
| **Apache Polaris** | Iceberg REST Catalog for table management |

## Prerequisites

- Docker Engine 20.10+ and Docker Compose v2
- At least 8 GB RAM
- Create the Docker network (run once):
  ```bash
  docker network create share-enterprise-ci
  ```

## Quick Start

### Step 1: Build and Start

```bash
cd lakehouse/singlecluster
docker compose build
docker compose up -d
```

### Step 2: Start Services

Enter the lakehouse container and start all services:
```bash
docker compose exec lakehouse bash
/opt/start-all.sh
```

Enter the polaris container and start Polaris:
```bash
docker compose exec polaris bash
./bin/server start
```

### Step 3: Setup Polaris Catalog

Inside the lakehouse container:
```bash
# Install jq (required, run once)
/workspace/scripts/install_jq.sh

# Create catalog and namespace
/workspace/scripts/polaris_cli.sh create-namespace

# Grant DROP TABLE WITH PURGE permission
/workspace/scripts/polaris_cli.sh grant-drop-with-purge
```

Done! Your lakehouse is ready.

## Services and Ports

| Service | Port | URL | Credentials |
|---------|------|-----|-------------|
| HDFS NameNode UI | 9870 | http://localhost:9870 | - |
| HDFS DataNode | 9864 | - | - |
| Hive Metastore | 9083 | thrift://localhost:9083 | - |
| HiveServer2 | 10000 | jdbc:hive2://localhost:10000 | - |
| Spark Master UI | 8080 | http://localhost:8080 | - |
| Spark History | 18080 | http://localhost:18080 | - |
| MinIO API | 9100 | http://localhost:9100 | admin / password |
| MinIO Console | 9200 | http://localhost:9200 | admin / password |
| Polaris API | 18181 | http://localhost:18181 | root / s3cr3t |
| Polaris Health | 18182 | http://localhost:18182/q/health | - |

## Polaris CLI Commands

All commands run inside the lakehouse container:

```bash
# Enter container
docker compose exec lakehouse bash
cd /workspace/scripts
```

| Command | Description |
|---------|-------------|
| `./polaris_cli.sh create-catalog` | Create a catalog |
| `./polaris_cli.sh create-namespace` | Create catalog + namespace |
| `./polaris_cli.sh list-catalogs` | List all catalogs |
| `./polaris_cli.sh list-namespaces` | List namespaces in catalog |
| `./polaris_cli.sh list-catalog-roles` | List catalog roles |
| `./polaris_cli.sh list-grants` | List permissions of catalog role |
| `./polaris_cli.sh grant-drop-with-purge` | Grant DROP TABLE WITH PURGE permission |
| `./polaris_cli.sh delete-catalog` | Delete catalog (fails if not empty) |
| `./polaris_cli.sh delete-catalog-force` | Delete catalog + all tables/namespaces |

### Environment Variables

Override defaults by setting these before running commands:

| Variable | Default | Description |
|----------|---------|-------------|
| `API_HOST` | http://singlecluster-polaris-1:8181 | Polaris API endpoint |
| `REALM` | POLARIS | Polaris realm |
| `CATALOG_NAME` | polaris_default_catalog | Catalog name |
| `NS_NAME` | public | Namespace name |
| `ROOT_CLIENT_ID` | root | Polaris client ID |
| `ROOT_CLIENT_SECRET` | s3cr3t | Polaris client secret |
| `S3_LOCATION` | s3://warehouse | Default S3 location |
| `S3_ENDPOINT` | http://lakehouse:9100 | MinIO endpoint |
| `S3_ACCESS_KEY` | admin | MinIO access key |
| `S3_SECRET_KEY` | password | MinIO secret key |

Example with custom values:
```bash
CATALOG_NAME=my_catalog NS_NAME=my_ns ./polaris_cli.sh create-namespace
```

## Using Polaris with Java/Spark

Connect to Polaris from your Iceberg client:

```java
Map<String, String> props = new HashMap<>();
props.put("uri", "http://localhost:18181/api/catalog");
props.put("credential", "root:s3cr3t");
props.put("scope", "PRINCIPAL_ROLE:ALL");
props.put("header.Polaris-Realm", "POLARIS");
props.put("warehouse", "polaris_default_catalog");

RESTCatalog catalog = new RESTCatalog();
catalog.initialize("polaris", props);
```

The catalog automatically provides S3 credentials to clients - no need to configure MinIO access in your code.

## Common Commands

### Hive
```bash
docker compose exec lakehouse beeline -u jdbc:hive2://localhost:10000 -n hive
```

### Spark SQL
```bash
docker compose exec lakehouse spark-sql
```

### MinIO (mc client)
```bash
docker compose exec lakehouse mc ls local/warehouse
```

## Shutdown

Stop containers (data is preserved in `./data/`):
```bash
docker compose down
```

Clean restart (delete all data):
```bash
docker compose down
rm -rf ./data/*
docker compose up -d
```

## Troubleshooting

### "DROP_TABLE_WITH_PURGE not authorized"
Run the grant command:
```bash
./polaris_cli.sh grant-drop-with-purge
```

### "Access Key Id does not exist"
The catalog may be missing S3 credentials. Recreate it:
```bash
./polaris_cli.sh delete-catalog-force
./polaris_cli.sh create-namespace
./polaris_cli.sh grant-drop-with-purge
```

### Polaris not responding
Check if the server is running:
```bash
docker compose exec polaris ps aux | grep java
```
If not, start it:
```bash
docker compose exec polaris ./bin/server start
```

### View logs
```bash
# Lakehouse services
docker compose logs -f lakehouse

# Polaris
docker compose logs -f polaris
```
