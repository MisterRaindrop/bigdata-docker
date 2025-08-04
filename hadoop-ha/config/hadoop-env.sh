#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

##
## THIS FILE ACTS AS THE MASTER FILE FOR ALL HADOOP PROJECTS.
## SETTINGS HERE WILL BE READ BY ALL HADOOP COMMANDS.  THEREFORE,
## ONE CAN USE THIS FILE TO SET YARN, HDFS, AND MAPREDUCE
## CONFIGURATION OPTIONS INSTEAD OF xxx-env.sh.
##
## Precedence rules:
##
## {yarn-env.sh|hdfs-env.sh} > hadoop-env.sh > hard-coded defaults
##
## {YARN_xyz|HDFS_xyz} > HADOOP_xyz > hard-coded defaults
##

# Many of the options here are built from the perspective that users
# may want to provide OVERRIDES for individual daemons.  Therefore,
# one may find numerous _OPT keywords in this file.

##
## Mandatory settings for all environments
##

# The java implementation to use. By default, this environment
# variable is REQUIRED on ALL platforms except OS X!
export JAVA_HOME=/usr/lib/jvm/jre

# Location of Hadoop.  By default, Hadoop will attempt to determine
# this location based upon its execution path.
export HADOOP_HOME=/opt/hadoop

# Location of Hadoop's configuration information.  i.e., where this
# file is living. If this is not defined, Hadoop will attempt to
# locate it based upon its execution path.
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop

# The maximum amount of heap to use (Java -Xmx).  If no unit
# is provided, it will be converted to MB.  Daemons will
# prefer any Xmx setting in their respective _OPT variable.
# There is no default; the JVM will autoscale based upon machine
# memory size.
export HADOOP_HEAPSIZE_MAX=1g

# The minimum amount of heap to use (Java -Xms).  If no unit
# is provided, it will be converted to MB.  Daemons will
# prefer any Xms setting in their respective _OPT variable.
# There is no default; the JVM will autoscale based upon machine
# memory size.
export HADOOP_HEAPSIZE_MIN=256m

# Enable extra debugging of Hadoop's JAAS binding, used to set up
# Kerberos security.
# export HADOOP_JAAS_DEBUG=true

# Extra Java runtime options for all Hadoop commands. We don't support
# IPv6 yet/still, so by default the preference is set to IPv4.
export HADOOP_OPTS="-Djava.net.preferIPv4Stack=true"
export HADOOP_OPTS="${HADOOP_OPTS} -Dhadoop.log.dir=${HADOOP_LOG_DIR}"
export HADOOP_OPTS="${HADOOP_OPTS} -Dhadoop.log.file=${HADOOP_LOGFILE}"
export HADOOP_OPTS="${HADOOP_OPTS} -Dhadoop.home.dir=${HADOOP_HOME}"
export HADOOP_OPTS="${HADOOP_OPTS} -Dhadoop.id.str=${HADOOP_IDENT_STRING}"
export HADOOP_OPTS="${HADOOP_OPTS} -Dhadoop.root.logger=${HADOOP_ROOT_LOGGER:-INFO,console}"
export HADOOP_OPTS="${HADOOP_OPTS} -Dhadoop.policy.file=hadoop-policy.xml"
export HADOOP_OPTS="${HADOOP_OPTS} -Dhadoop.security.logger=${HADOOP_SECURITY_LOGGER:-INFO,NullAppender}"

# Extra Java runtime options for some Hadoop commands
# and clients (i.e., commands executed by users).  These get added to HADOOP_OPTS for
# such commands.  In most cases, this should be left empty and
# let users supply it on the command line.
# export HADOOP_CLIENT_OPTS=""

#
# A note about classpaths.
#
# By default, Apache Hadoop overrides Java's CLASSPATH
# environment variable.  It is configured such
# that it starts out blank with new entries added after passing
# a series of checks (file/dir exists, not already listed aka
# de-deduplication).  During de-deduplication, wildcards and/or
# directories are *NOT* expanded to keep it simple. Therefore,
# if the computed classpath has two specific mentions of
# a wildcard entry, it will have two entries.  Under those
# circumstances, the last one added will take precedence.
# See HADOOP-7904 for more information.

# Sets the default value for the -server parameter (default: true)
# export HADOOP_ENABLE_SERVER_JVM="true"

##
## JournalNode specific parameters
##

# Specify the JVM options to be used when starting the JournalNode.
# These options will be appended to the options specified as HADOOP_OPTS
# and therefore may override any similar flags set in HADOOP_OPTS
#
# Examples for a Sun/Oracle JDK:
# a) override the appsrv jvm args for this command
# export HADOOP_JOURNALNODE_OPTS="-Xmx1024m"
# b) Set JMX options
# export HADOOP_JOURNALNODE_OPTS="-Xmx1024m -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=8005"
# c) Set gclog options
# export HADOOP_JOURNALNODE_OPTS="-Xmx1024m -Xloggc:${HADOOP_LOG_DIR}/gc-journalnode.log -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps"
#
# this is the default:
export HADOOP_JOURNALNODE_OPTS="-Xmx512m ${HADOOP_JOURNALNODE_OPTS}"

##
## NameNode specific parameters
##

# Specify the JVM options to be used when starting the NameNode.
# These options will be appended to the options specified as HADOOP_OPTS
# and therefore may override any similar flags set in HADOOP_OPTS
#
# a) Set JMX options
# export HADOOP_NAMENODE_OPTS="-Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=8004"
# b) Set gclog options
# export HADOOP_NAMENODE_OPTS="-Xloggc:${HADOOP_LOG_DIR}/gc-namenode.log -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps"
#
# this is the default:
export HADOOP_NAMENODE_OPTS="-Xmx1024m ${HADOOP_NAMENODE_OPTS}"

##
## DataNode specific parameters
##

# Specify the JVM options to be used when starting the DataNode.
# These options will be appended to the options specified as HADOOP_OPTS
# and therefore may override any similar flags set in HADOOP_OPTS
#
# This is the default:
export HADOOP_DATANODE_OPTS="-Xmx512m ${HADOOP_DATANODE_OPTS}"

##
## YARN specific parameters
##

# Specify the max heapsize for the ResourceManager.  If no units are
# given, it will be assumed to be in MB.
# This value will be overridden by an Xmx setting specified in either
# YARN_RESOURCEMANAGER_OPTS or YARN_OPTS.
export YARN_RESOURCEMANAGER_HEAPSIZE=1024

# Specify the max heapsize for the NodeManager.  If no units are
# given, it will be assumed to be in MB.
# This value will be overridden by an Xmx setting specified in either
# YARN_NODEMANAGER_OPTS or YARN_OPTS.
export YARN_NODEMANAGER_HEAPSIZE=1024

# Specify the max heapsize for the timeline service.  If no units are
# given, it will be assumed to be in MB.
# This value will be overridden by an Xmx setting specified in either
# YARN_TIMELINESERVICE_OPTS or YARN_OPTS.
export YARN_TIMELINESERVICE_HEAPSIZE=1024

# Specify the max heapsize for the HistoryServer.  If no units are
# given, it will be assumed to be in MB.
# This value will be overridden by an Xmx setting specified in either
# YARN_HISTORYSERVER_OPTS or YARN_OPTS.
export YARN_HISTORYSERVER_HEAPSIZE=1024 