#!/usr/bin/env bash
set -euo pipefail

export HADOOP_HOME=${HADOOP_HOME:-/opt/hadoop}
export HIVE_HOME=${HIVE_HOME:-/opt/hive}
export SPARK_HOME=${SPARK_HOME:-/opt/spark}
export HIVE_CONF_DIR=${HIVE_HOME}/conf
export PATH=$PATH:${HADOOP_HOME}/bin:${HIVE_HOME}/bin:${SPARK_HOME}/bin

export MINIO_ROOT_USER=${MINIO_ROOT_USER:-minio}
export MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD:-minio123}
export S3_ENDPOINT=${S3_ENDPOINT:-http://localhost:9100}
export S3_ACCESS_KEY=${S3_ACCESS_KEY:-${MINIO_ROOT_USER}}
export S3_SECRET_KEY=${S3_SECRET_KEY:-${MINIO_ROOT_PASSWORD}}
export WAREHOUSE_S3=${WAREHOUSE_S3:-s3a://warehouse/}
export HDFS_NN_URI=${HDFS_NN_URI:-hdfs://localhost:8020}
export METASTORE_DB_USER=${METASTORE_DB_USER:-hive}
export METASTORE_DB_PASS=${METASTORE_DB_PASS:-hivepw}
export METASTORE_DB_NAME=${METASTORE_DB_NAME:-metastore}

LOG_DIR=/var/log/lakehouse
mkdir -p "${LOG_DIR}"

echo "[stage] copy jars into Spark/Hive" | tee -a "${LOG_DIR}/startup.log"
cp /opt/jars/* "${SPARK_HOME}/jars/"
cp /opt/jars/* "${HIVE_HOME}/lib/"

echo "[stage] write Hadoop/Hive/Spark configs" | tee -a "${LOG_DIR}/startup.log"
cat > "${HADOOP_HOME}/etc/hadoop/core-site.xml" <<EOF
<?xml version="1.0"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>${HDFS_NN_URI}</value>
  </property>
  <property>
    <name>fs.s3a.endpoint</name>
    <value>${S3_ENDPOINT}</value>
  </property>
  <property>
    <name>fs.s3a.access.key</name>
    <value>${S3_ACCESS_KEY}</value>
  </property>
  <property>
    <name>fs.s3a.secret.key</name>
    <value>${S3_SECRET_KEY}</value>
  </property>
  <property>
    <name>fs.s3a.path.style.access</name>
    <value>true</value>
  </property>
</configuration>
EOF

cat > "${HADOOP_HOME}/etc/hadoop/hdfs-site.xml" <<EOF
<?xml version="1.0"?>
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:/data/hdfs/nn</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:/data/hdfs/dn</value>
  </property>
  <property>
    <name>dfs.permissions.enabled</name>
    <value>false</value>
  </property>
</configuration>
EOF

cat > "${HIVE_CONF_DIR}/hive-site.xml" <<EOF
<?xml version="1.0"?>
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:postgresql://localhost:5432/${METASTORE_DB_NAME}</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.postgresql.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>${METASTORE_DB_USER}</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>${METASTORE_DB_PASS}</value>
  </property>
  <property>
    <name>datanucleus.autoCreateSchema</name>
    <value>false</value>
  </property>
  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://localhost:9083</value>
  </property>
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>${WAREHOUSE_S3}</value>
  </property>
  <property>
    <name>hive.support.concurrency</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.txn.manager</name>
    <value>org.apache.hadoop.hive.ql.lockmgr.DbTxnManager</value>
  </property>
  <property>
    <name>hive.compactor.initiator.on</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.compactor.worker.threads</name>
    <value>1</value>
  </property>
</configuration>
EOF

mkdir -p "${SPARK_HOME}/conf"
cat > "${SPARK_HOME}/conf/spark-defaults.conf" <<EOF
spark.master                     spark://localhost:7077
spark.eventLog.enabled           true
spark.eventLog.dir               ${WAREHOUSE_S3}/spark-events
spark.history.fs.logDirectory    ${WAREHOUSE_S3}/spark-events
spark.sql.catalogImplementation  hive
spark.sql.extensions             org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
spark.sql.catalog.spark_catalog  org.apache.iceberg.spark.SparkSessionCatalog
spark.sql.catalog.spark_catalog.type hive
spark.sql.catalog.spark_catalog.warehouse ${WAREHOUSE_S3}
spark.hadoop.fs.s3a.endpoint     ${S3_ENDPOINT}
spark.hadoop.fs.s3a.path.style.access true
spark.hadoop.fs.s3a.access.key   ${S3_ACCESS_KEY}
spark.hadoop.fs.s3a.secret.key   ${S3_SECRET_KEY}
spark.hadoop.fs.defaultFS        ${HDFS_NN_URI}
EOF

echo "[stage] start PostgreSQL" | tee -a "${LOG_DIR}/startup.log"
PG_VERSION=$(ls /etc/postgresql | head -n1)
pg_ctlcluster "${PG_VERSION}" main start
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${METASTORE_DB_USER}'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER ${METASTORE_DB_USER} WITH PASSWORD '${METASTORE_DB_PASS}'"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${METASTORE_DB_NAME}'" | grep -q 1 || \
  sudo -u postgres createdb "${METASTORE_DB_NAME}"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${METASTORE_DB_NAME} TO ${METASTORE_DB_USER}" || true

echo "[stage] format and start HDFS" | tee -a "${LOG_DIR}/startup.log"
if [ ! -f /data/hdfs/nn/current/VERSION ]; then
  hdfs namenode -format -force -nonInteractive
fi
hdfs --daemon start namenode
hdfs --daemon start datanode

echo "[stage] start MinIO" | tee -a "${LOG_DIR}/startup.log"
mkdir -p /data/warehouse
minio server /data/warehouse --address ":9100" --console-address ":9200" >"${LOG_DIR}/minio.log" 2>&1 &
sleep 3
mc alias set local http://127.0.0.1:9100 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null
mc mb -p local/warehouse >/dev/null || true

echo "[stage] init Hive schema" | tee -a "${LOG_DIR}/startup.log"
/opt/init-metastore.sh

echo "[stage] start Hive Metastore and HS2" | tee -a "${LOG_DIR}/startup.log"
nohup ${HIVE_HOME}/bin/hive --service metastore >"${LOG_DIR}/hivemetastore.log" 2>&1 &
sleep 5
nohup ${HIVE_HOME}/bin/hive --service hiveserver2 >"${LOG_DIR}/hiveserver2.log" 2>&1 &

echo "[stage] start Spark" | tee -a "${LOG_DIR}/startup.log"
${SPARK_HOME}/sbin/start-master.sh
${SPARK_HOME}/sbin/start-worker.sh spark://localhost:7077
${SPARK_HOME}/sbin/start-history-server.sh

echo "[ready] services started, tailing logs" | tee -a "${LOG_DIR}/startup.log"
tail -n 200 -f "${LOG_DIR}/startup.log"

