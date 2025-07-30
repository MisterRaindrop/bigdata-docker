#!/bin/bash

# 创建journal目录并设置权限
mkdir -p /opt/hadoop/journal
chown -R hadoop:hadoop /opt/hadoop/journal
chmod 755 /opt/hadoop/journal

# 直接启动JournalNode（不使用su）
exec hdfs journalnode 