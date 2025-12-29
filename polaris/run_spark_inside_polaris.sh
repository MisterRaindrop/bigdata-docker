#!/usr/bin/env bash
# 在 Polaris 容器内运行 spark-sql，通过 REST 写 Iceberg 表的示例。

set -euo pipefail

# 可覆盖的环境变量
SPARK_VERSION="${SPARK_VERSION:-3.5.0}"
SPARK_PACKAGE="spark-${SPARK_VERSION}-bin-hadoop3"
SPARK_TGZ="${SPARK_PACKAGE}.tgz"
SPARK_URL="${SPARK_URL:-https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_TGZ}}"
SPARK_HOME="${SPARK_HOME:-/tmp/${SPARK_PACKAGE}}"
SPARK_BIN="${SPARK_BIN:-${SPARK_HOME}/bin/spark-sql}"
SPARK_IVY_DIR="${SPARK_IVY_DIR:-/tmp/.ivy2}"
CLIENT_ID="${CLIENT_ID:-root}"
CLIENT_SECRET="${CLIENT_SECRET:-s3cr3t}"
POLARIS_URI="${POLARIS_URI:-http://localhost:8181/api/catalog}"
OAUTH_URI="${OAUTH_URI:-http://localhost:8181/api/catalog/v1/oauth/tokens}"
S3_ENDPOINT="${S3_ENDPOINT:-http://localhost:9000}"
WAREHOUSE="${WAREHOUSE:-polaris}"
NAMESPACE="${NAMESPACE:-test_ns}"
TABLE="${TABLE:-sample_tbl}"
SPARK_EXTRA_CONF="${SPARK_EXTRA_CONF:-}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "缺少命令：$1"; exit 1; }
}

need_cmd curl
need_cmd tar

extract_with_python() {
  local py_bin=""
  if command -v python3 >/dev/null 2>&1; then
    py_bin=python3
  elif command -v python >/dev/null 2>&1; then
    py_bin=python
  else
    echo "缺少 gzip 且不存在 python，无法解压 ${SPARK_TGZ}。"
    exit 1
  fi
  "${py_bin}" - <<PY
import tarfile
path = "/tmp/${SPARK_TGZ}"
dest = "/tmp"
with tarfile.open(path, "r:gz") as tar:
    tar.extractall(dest)
PY
}

extract_spark() {
  if command -v gzip >/dev/null 2>&1; then
    tar -xzf "/tmp/${SPARK_TGZ}" -C /tmp
  else
    echo "gzip 不可用，改用 python 解压..."
    extract_with_python
  fi
}

# 下载 Spark（若未存在）
if [ ! -x "${SPARK_BIN}" ]; then
  echo "下载 Spark ${SPARK_VERSION}..."
  mkdir -p /tmp
  curl -fL "${SPARK_URL}" -o "/tmp/${SPARK_TGZ}"
  extract_spark
fi

mkdir -p "${SPARK_IVY_DIR}/cache"

echo "启动 spark-sql 连接 Polaris..."
"${SPARK_BIN}" \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.10.0,org.apache.iceberg:iceberg-aws-bundle:1.10.0 \
  --conf "spark.jars.ivy=${SPARK_IVY_DIR}" \
  --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
  --conf spark.sql.catalog.polaris=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.polaris.type=rest \
  --conf spark.sql.catalog.polaris.uri="${POLARIS_URI}" \
  --conf spark.sql.catalog.polaris.oauth2-server-uri="${OAUTH_URI}" \
  --conf spark.sql.catalog.polaris.credential="${CLIENT_ID}:${CLIENT_SECRET}" \
  --conf spark.sql.catalog.polaris.scope=PRINCIPAL_ROLE:ALL \
  --conf spark.sql.catalog.polaris.warehouse="${WAREHOUSE}" \
  --conf spark.sql.catalog.polaris.s3.endpoint="${S3_ENDPOINT}" \
  --conf spark.sql.catalog.polaris.s3.path-style-access=true \
  --conf spark.sql.catalog.polaris.s3.access-key-id=minio_root \
  --conf spark.sql.catalog.polaris.s3.secret-access-key=m1n1opwd \
  --conf spark.sql.catalog.polaris.client.region=irrelevant \
  --conf spark.sql.defaultCatalog=polaris \
  ${SPARK_EXTRA_CONF} \
<<SQL
CREATE NAMESPACE IF NOT EXISTS ${NAMESPACE};

CREATE TABLE IF NOT EXISTS polaris.${NAMESPACE}.${TABLE} (
  id   BIGINT,
  name STRING,
  age  INT,
  city STRING
) USING iceberg;

INSERT INTO polaris.${NAMESPACE}.${TABLE} VALUES
  (1,'Alice',25,'NY'),
  (2,'Bob',30,'London'),
  (3,'Carol',32,'Paris');

SELECT * FROM polaris.${NAMESPACE}.${TABLE};
SQL

echo "✅ 完成。可在 MinIO bucket123 查看数据文件，或用 REST 查询表元数据。"

