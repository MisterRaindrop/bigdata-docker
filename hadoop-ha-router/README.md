# Hadoop HA with HDFS Router Deployment Guide

这是一个基于 Docker Compose 的 Hadoop HA 集群，集成 HDFS Router（路由器），支持通过 Router 统一入口访问 HDFS。目录简洁、支持 Ubuntu 和 CentOS 7，使用外部网络 `share-enterprise-ci`，便于其它容器通过主机名访问。

## 特性
- Hadoop 3 HA（NameNode×2、JournalNode×3、DataNode×3）
- HDFS Router 统一入口（RPC/HTTP/Admin）
- YARN（ResourceManager×2）
- 整洁布局：一个 compose、一个启动脚本、一个停止脚本
- 使用外部网络 `share-enterprise-ci`，其它容器只需加入该网络即可按主机名访问

## 前置条件
- 已安装 Docker 与 Docker Compose（Ubuntu/CentOS 7 均可）
- 外部网络存在：
```bash
docker network ls | grep share-enterprise-ci || docker network create share-enterprise-ci
```

## 快速开始
```bash
cd hadoop-ha-router
# 启动并初始化 Hadoop HA + Router
./start-cluster.sh

# 验证 HDFS
docker exec namenode1 hdfs dfsadmin -report

# 验证 Router HTTP
curl -I http://router:50071
```

## 访问方式
- Router（推荐统一入口）：
  - RPC：`router:8888`（客户端可用 `fs.defaultFS=hdfs://router:8888`）
  - HTTP：`http://router:50071`
  - Admin：`router:8111`
- NameNode：
  - NN1：`namenode1:9820`（RPC）、`http://namenode1:9870`
  - NN2：`namenode2:9820`（RPC）、`http://namenode2:9870`

其它 Docker 容器如需访问，请加入网络：
```bash
docker network connect share-enterprise-ci <your-container>
```

## 目录结构
```
hadoop-ha-router/
├── README.md
├── docker-compose.yml
├── start-cluster.sh
├── stop-cluster.sh
├── config/
│   ├── core-site.xml
│   ├── hdfs-site.xml
│   ├── yarn-site.xml
│   ├── hadoop-env.sh
│   ├── workers
│   └── mount-table.xml     # Router 挂载表：将 / 路由到 mycluster
```

## 说明
- 默认启用 ZKFC 自动故障转移，需要 ZooKeeper 可用。
- Router 的挂载表将根路径 `/` 路由到 nameservice `mycluster`。

## 清理
```bash
./stop-cluster.sh
```