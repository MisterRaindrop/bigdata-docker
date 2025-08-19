#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Ensure external docker network exists
if ! docker network ls | grep -q "share-enterprise-ci"; then
  docker network create share-enterprise-ci
fi

echo "[1/3] Starting containers..."
docker-compose up -d

# Wait for base containers
sleep 10

exec_in() { docker exec "$1" bash -lc "$2"; }

# Fix permissions for HDFS paths
for c in journalnode1 journalnode2 journalnode3 namenode1 namenode2 datanode1 datanode2 datanode3; do
  exec_in "$c" "mkdir -p /hadoop/dfs/{journal,name,data} && chown -R hadoop:hadoop /hadoop && chmod -R 755 /hadoop"
done

# Start JournalNodes
for j in 1 2 3; do
  docker exec -d journalnode$j hdfs journalnode
  sleep 2
done

# Format ZK for ZKFC
exec_in namenode1 "hdfs zkfc -formatZK -force || true"

# Format NameNode1 & bootstrap NameNode2
exec_in namenode1 "hdfs namenode -format -force -nonInteractive"
docker exec -d namenode1 hdfs namenode
sleep 15

exec_in namenode2 "hdfs namenode -bootstrapStandby -force -nonInteractive"
docker exec -d namenode2 hdfs namenode
sleep 15

# Start ZKFC
for n in namenode1 namenode2; do
  docker exec -d "$n" hdfs zkfc
  sleep 2
done

# Start DataNodes
for d in 1 2 3; do
  docker exec -d datanode$d hdfs datanode
  sleep 2
done

# Start ResourceManagers (optional)
docker exec -d resourcemanager1 yarn resourcemanager || true
docker exec -d resourcemanager2 yarn resourcemanager || true

# Start Router services: RPC/HTTP/Admin (run in background)
docker exec -d router hdfs router

# Report
exec_in namenode1 "hdfs dfsadmin -report"

echo "Cluster with Router started. Access via 'router:8888' RPC and 'http://router:50071' HTTP on share-enterprise-ci."