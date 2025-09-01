#!/bin/bash

# Ensure HDFS directories exist
echo "Creating HDFS directories..."
docker exec -it namenode1 bash -lc "hdfs dfs -mkdir -p /iceberg/warehouse /iceberg/hive/warehouse && hdfs dfs -chmod -R 777 /iceberg"

# Create Iceberg table through Spark SQL
echo "Creating Iceberg table..."
docker exec -it spark-iceberg spark-sql --conf spark.sql.catalog.hadoop=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.hadoop.type=hadoop \
  --conf spark.sql.catalog.hadoop.warehouse=hdfs://mycluster/iceberg/warehouse \
  -e "
-- Create database
CREATE DATABASE IF NOT EXISTS hadoop.testdb;

-- Create Iceberg table
CREATE TABLE IF NOT EXISTS hadoop.testdb.test_table (
  id INT,
  name STRING,
  create_time TIMESTAMP
) USING iceberg;

-- Insert data
INSERT INTO hadoop.testdb.test_table VALUES 
  (1, 'test1', current_timestamp()),
  (2, 'test2', current_timestamp()),
  (3, 'test3', current_timestamp());

-- Query data
SELECT * FROM hadoop.testdb.test_table;

-- View table metadata
DESCRIBE EXTENDED hadoop.testdb.test_table;

-- View table history
SELECT * FROM hadoop.testdb.test_table.history;
"

# View files on HDFS
echo "Viewing files on HDFS..."
docker exec -it namenode1 bash -lc "hdfs dfs -ls -R /iceberg/warehouse/testdb/test_table"
