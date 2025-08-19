# Iceberg REST and Spark Iceberg Local Environment

This directory provides a local environment for Iceberg REST + MinIO + Spark that is connected to the external Docker network `share-enterprise-ci`. Ports are chosen to avoid conflicts with other Compose projects in this repo (e.g., `hadoop-ha`, `hadoop-ha-router`).

## Components
- spark-iceberg: Interactive Spark (with Jupyter Notebook and Spark Thrift)
- iceberg-rest: Example Iceberg REST Catalog service
- minio: S3-compatible object storage
- mc: MinIO client for bucket initialization

## Ports and Networks
- Port mappings
  - spark-iceberg:
    - 18888 -> 8888 (Jupyter; avoids conflict with `hadoop-ha-router`'s 8888)
    - 8080  -> 8080 (Spark UI)
    - 10000 -> 10000 (Spark Thrift Server)
    - 10001 -> 10001 (Spark Thrift Server HTTP)
  - iceberg-rest: 8181 -> 8181
  - minio:
    - 9000 -> 9000 (S3 endpoint)
    - 9001 -> 9001 (MinIO Console)
- Networks
  - Internal network: `iceberg_net`
  - External network: `share-enterprise-ci` (referenced as `app-network` in the Compose file)

If the external network does not exist yet, create it first:
```bash
docker network create share-enterprise-ci || true
```

## Directory Layout and Mounts
- `./warehouse` is mounted to `/home/iceberg/warehouse` (Iceberg warehouse metadata)
- `./notebooks` is mounted to `/home/iceberg/notebooks/notebooks` (sample and custom notebooks)

## Start and Stop
From this directory run:
```bash
docker compose up -d
```
Stop and clean up:
```bash
docker compose down
```

### One-click start script
You can also use the helper script:
```bash
./start.sh              # start only iceberg-rest stack
./start.sh --with-hadoop# start hadoop-ha first, then iceberg-rest
```

## First-time Initialization
The `mc` container will automatically:
- Configure the MinIO alias and wait for MinIO to be ready
- Remove and recreate the `warehouse` bucket
- Set the `warehouse` bucket policy to public

Key Iceberg REST environment variables:
- `CATALOG_WAREHOUSE=s3://warehouse/`
- `CATALOG_IO__IMPL=org.apache.iceberg.aws.s3.S3FileIO`
- `CATALOG_S3_ENDPOINT=http://minio:9000`

## Endpoints
- Jupyter (spark-iceberg): http://localhost:18888
- Spark UI (spark-iceberg): http://localhost:8080
- Iceberg REST: http://localhost:8181
- MinIO Console: http://localhost:9001 (username/password: admin/password)
- MinIO S3 endpoint: http://localhost:9000

## Connectivity Tests
- Test REST:
```bash
curl http://localhost:8181/v1/config
```
- Test MinIO:
```bash
aws --endpoint-url http://localhost:9000 s3 ls
```
Or use the MinIO Console in your browser.

## Interoperability with Hadoop Cluster
Because this environment joins the external network `share-enterprise-ci`, it can communicate with `hadoop-ha` and/or `hadoop-ha-router` that are on the same network. Ensure those projects also use the same external network.

### Reusing hadoop-ha (HDFS) for Iceberg Hadoop/Hive Catalogs
This stack is configured to reuse the HDFS provided by `hadoop-ha`:
- HadoopCatalog warehouse: `hdfs://mycluster/iceberg/warehouse`
- HiveCatalog warehouse: `hdfs://mycluster/iceberg/hive/warehouse`

Ways to start and reuse `hadoop-ha`:
1) One-click with script (recommended):
```bash
./start.sh --with-hadoop
```
2) Manual steps:
```bash
docker network create share-enterprise-ci || true
cd ../hadoop-ha && docker compose up -d
cd - && docker compose up -d
```

First-time HDFS initialization (once):
```bash
docker exec -it namenode1 bash -lc "hdfs dfs -mkdir -p /iceberg/warehouse /iceberg/hive/warehouse && hdfs dfs -chmod -R 777 /iceberg"
```
After that, Spark can access HDFS via HA nameservice `mycluster` using the mounted `core-site.xml` and `hdfs-site.xml`.

## FAQ
- Port already in use:
  - If your host already uses `8080/9000/9001/10000/10001`, adjust the left-hand host port in `docker-compose.yml` (e.g., change `8080:8080` to `18080:8080`).
- Cannot access REST/MinIO:
  - Ensure all containers are running and the external network `share-enterprise-ci` exists.

## Clean Up Data
If you need to clear the object storage during development/testing:
```bash
docker compose exec mc /usr/bin/mc rm -r --force minio/warehouse
```