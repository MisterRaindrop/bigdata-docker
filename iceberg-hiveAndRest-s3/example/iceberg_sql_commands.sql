CREATE DATABASE IF NOT EXISTS hadoop.testdb;

CREATE TABLE IF NOT EXISTS hadoop.testdb.test_table (
  id INT,
  name STRING,
  create_time TIMESTAMP
) USING iceberg;

INSERT INTO hadoop.testdb.test_table VALUES 
  (1, 'test1', current_timestamp()),
  (2, 'test2', current_timestamp()),
  (3, 'test3', current_timestamp());

SELECT * FROM hadoop.testdb.test_table;

DESCRIBE EXTENDED hadoop.testdb.test_table;

SELECT * FROM hadoop.testdb.test_table.history;
