#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WITH_HADOOP="false"
if [[ "${1:-}" == "--with-hadoop" ]]; then
	WITH_HADOOP="true"
fi

echo "[+] Ensuring external docker network 'share-enterprise-ci' exists..."
if ! docker network inspect share-enterprise-ci >/dev/null 2>&1; then
	docker network create share-enterprise-ci >/dev/null
	echo "    created network 'share-enterprise-ci'"
else
	echo "    network 'share-enterprise-ci' already exists"
fi

echo "[+] Ensuring required local directories exist..."
mkdir -p "$SCRIPT_DIR/warehouse" \
	"$SCRIPT_DIR/notebooks" \
	"$SCRIPT_DIR/postgres-data" \
	"$SCRIPT_DIR/jars"

if [[ "$WITH_HADOOP" == "true" ]]; then
	HADOOP_DIR="$SCRIPT_DIR/../hadoop-ha"
	HADOOP_START_SCRIPT="$HADOOP_DIR/start-cluster.sh"
	if [[ -f "$HADOOP_START_SCRIPT" ]]; then
		echo "[+] Starting Hadoop HA cluster via start-cluster.sh..."
		( cd "$HADOOP_DIR" && chmod +x "$HADOOP_START_SCRIPT" && "$HADOOP_START_SCRIPT" )
	else
		echo "[!] Skipping Hadoop start: script not found at $HADOOP_START_SCRIPT"
	fi
fi

echo "[+] Starting iceberg-rest stack..."
( cd "$SCRIPT_DIR" && docker compose up -d )

echo "[+] Done. Endpoints:"
echo "    Iceberg REST:       http://localhost:8181"
echo "    MinIO Console:      http://localhost:9001 (admin/password)"
echo "    MinIO S3:           http://localhost:9000"
echo "    Hive Metastore:     thrift://localhost:9083"
echo "    Postgres (Meta):    localhost:5432 (hive/hivepass123, db=metastore)"
echo "    Spark Jupyter:      http://localhost:18888"
echo "    Spark UI:           http://localhost:8080"

if [[ "$WITH_HADOOP" == "true" ]]; then
	echo "[i] If this is the first run, initialize HDFS path for HadoopCatalog:"
	echo "    docker exec -it namenode1 bash -lc \"hdfs dfs -mkdir -p /iceberg/warehouse /iceberg/hive/warehouse && hdfs dfs -chmod -R 777 /iceberg\""
fi

echo "[i] To stop: run 'docker compose down' inside $SCRIPT_DIR (and in hadoop-ha if started)"
