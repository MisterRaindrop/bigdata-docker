#!/bin/bash

echo "Testing Nginx proxy access to Hadoop services..."

# Test NameNode1
echo "Testing NameNode1 Web UI..."
if curl -s -f http://localhost/namenode1/ > /dev/null; then
    echo "✅ NameNode1 Web UI is accessible: http://localhost/namenode1/"
else
    echo "❌ NameNode1 Web UI is not accessible"
fi

# Test NameNode2
echo "Testing NameNode2 Web UI..."
if curl -s -f http://localhost/namenode2/ > /dev/null; then
    echo "✅ NameNode2 Web UI is accessible: http://localhost/namenode2/"
else
    echo "❌ NameNode2 Web UI is not accessible"
fi

# Test YARN
echo "Testing YARN Web UI..."
if curl -s -f http://localhost/yarn/ > /dev/null; then
    echo "✅ YARN Web UI is accessible: http://localhost/yarn/"
else
    echo "❌ YARN Web UI is not accessible"
fi

# Test DataNode1
echo "Testing DataNode1 Web UI..."
if curl -s -f http://localhost/datanode1/ > /dev/null; then
    echo "✅ DataNode1 Web UI is accessible: http://localhost/datanode1/"
else
    echo "❌ DataNode1 Web UI is not accessible"
fi

# Test DataNode2
echo "Testing DataNode2 Web UI..."
if curl -s -f http://localhost/datanode2/ > /dev/null; then
    echo "✅ DataNode2 Web UI is accessible: http://localhost/datanode2/"
else
    echo "❌ DataNode2 Web UI is not accessible"
fi

# Test DataNode3
echo "Testing DataNode3 Web UI..."
if curl -s -f http://localhost/datanode3/ > /dev/null; then
    echo "✅ DataNode3 Web UI is accessible: http://localhost/datanode3/"
else
    echo "❌ DataNode3 Web UI is not accessible"
fi

echo ""
echo "Access Address Summary:"
echo "  NameNode1: http://localhost/namenode1/"
echo "  NameNode2: http://localhost/namenode2/"
echo "  YARN: http://localhost/yarn/"
echo "  DataNode1: http://localhost/datanode1/"
echo "  DataNode2: http://localhost/datanode2/"
echo "  DataNode3: http://localhost/datanode3/"
echo ""
echo "Run RPC test: ./test-rpc.sh" 