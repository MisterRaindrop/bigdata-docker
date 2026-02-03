FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

ENV HADOOP_VERSION=3.3.6 \
    HIVE_VERSION=3.1.3 \
    SPARK_VERSION=3.3.3 \
    HUDI_VERSION=0.11.1 \
    ICEBERG_VERSION=1.1.0 \
    JAVA_HOME=/opt/java/openjdk \
    HADOOP_HOME=/opt/hadoop \
    HIVE_HOME=/opt/hive \
    SPARK_HOME=/opt/spark

ENV PATH=$PATH:$JAVA_HOME/bin:/opt/hadoop/bin:/opt/hive/bin:/opt/spark/bin

# Base tools and MinIO
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl wget procps netcat-openbsd lsof python3 \
    postgresql postgresql-contrib sudo gnupg \
 && rm -rf /var/lib/apt/lists/*

# Java 8 (Temurin) for Hive CLI compatibility
RUN mkdir -p /opt/java \
 && curl -fSL https://api.adoptium.net/v3/binary/latest/8/ga/linux/x64/jdk/hotspot/normal/eclipse -o /tmp/jdk8.tar.gz \
 && tar -xzf /tmp/jdk8.tar.gz -C /opt/java \
 && JDK_DIR=$(ls -d /opt/java/jdk* | head -n1) \
 && ln -s "${JDK_DIR}" /opt/java/openjdk \
 && rm /tmp/jdk8.tar.gz

RUN curl -L https://dl.min.io/server/minio/release/linux-amd64/minio -o /usr/local/bin/minio \
 && chmod +x /usr/local/bin/minio \
 && curl -L https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc \
 && chmod +x /usr/local/bin/mc

# Hadoop
RUN curl -fSL --retry 5 --retry-delay 10 --retry-max-time 120 \
    https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
  | tar -xz -C /opt \
 && ln -s /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME}

# Hive
RUN curl -fSL --retry 5 --retry-delay 10 --retry-max-time 120 \
    https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz \
  | tar -xz -C /opt \
 && ln -s /opt/apache-hive-${HIVE_VERSION}-bin ${HIVE_HOME}

# Spark
RUN curl -fSL --retry 5 --retry-delay 10 --retry-max-time 120 \
    https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz \
  | tar -xz -C /opt \
 && ln -s /opt/spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME}

# Dependency JARs: Hudi / Iceberg / S3A
RUN mkdir -p /opt/jars && cd /opt/jars && \
    curl -fSLO https://repo1.maven.org/maven2/org/apache/hudi/hudi-spark3-bundle_2.12/${HUDI_VERSION}/hudi-spark3-bundle_2.12-${HUDI_VERSION}.jar && \
    curl -fSLO https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.3_2.12/${ICEBERG_VERSION}/iceberg-spark-runtime-3.3_2.12-${ICEBERG_VERSION}.jar && \
    curl -fSLO https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar && \
    curl -fSLO https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar

# Startup scripts
COPY scripts/start-all.sh /opt/start-all.sh
COPY scripts/init-metastore.sh /opt/init-metastore.sh
RUN chmod +x /opt/start-all.sh /opt/init-metastore.sh

# Data directories
RUN mkdir -p /data/hdfs/nn /data/hdfs/dn /data/metastore-db /data/warehouse /var/log/lakehouse

EXPOSE 9870 9864 9083 10000 9100 9200 7077 8080 18080 8181 5432
ENTRYPOINT ["/opt/start-all.sh"]

