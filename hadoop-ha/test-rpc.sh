#!/bin/bash

echo "Testing Hadoop RPC service access..."

# Test NameNode1 RPC port
echo "Testing NameNode1 RPC port (9820)..."
if nc -z localhost 9820 2>/dev/null; then
    echo "✅ NameNode1 RPC port 9820 is accessible"
else
    echo "❌ NameNode1 RPC port 9820 is not accessible"
fi

# Test NameNode2 RPC port
echo "Testing NameNode2 RPC port (9821)..."
if nc -z localhost 9821 2>/dev/null; then
    echo "✅ NameNode2 RPC port 9821 is accessible"
else
    echo "❌ NameNode2 RPC port 9821 is not accessible"
fi

# Test DataNode1 RPC port
echo "Testing DataNode1 RPC port (9866)..."
if nc -z localhost 9866 2>/dev/null; then
    echo "✅ DataNode1 RPC port 9866 is accessible"
else
    echo "❌ DataNode1 RPC port 9866 is not accessible"
fi

# Test DataNode2 RPC port
echo "Testing DataNode2 RPC port (9867)..."
if nc -z localhost 9867 2>/dev/null; then
    echo "✅ DataNode2 RPC port 9867 is accessible"
else
    echo "❌ DataNode2 RPC port 9867 is not accessible"
fi

# Test DataNode3 RPC port
echo "Testing DataNode3 RPC port (9868)..."
if nc -z localhost 9868 2>/dev/null; then
    echo "✅ DataNode3 RPC port 9868 is accessible"
else
    echo "❌ DataNode3 RPC port 9868 is not accessible"
fi

# Test ResourceManager1 RPC port
echo "Testing ResourceManager1 RPC port (8030)..."
if nc -z localhost 8030 2>/dev/null; then
    echo "✅ ResourceManager1 RPC port 8030 is accessible"
else
    echo "❌ ResourceManager1 RPC port 8030 is not accessible"
fi

# Test ResourceManager2 RPC port
echo "Testing ResourceManager2 RPC port (8031)..."
if nc -z localhost 8031 2>/dev/null; then
    echo "✅ ResourceManager2 RPC port 8031 is accessible"
else
    echo "❌ ResourceManager2 RPC port 8031 is not accessible"
fi

echo ""
echo "RPC Port Summary:"
echo "  NameNode1 RPC: localhost:9820"
echo "  NameNode2 RPC: localhost:9821"
echo "  DataNode1 RPC: localhost:9866"
echo "  DataNode2 RPC: localhost:9867"
echo "  DataNode3 RPC: localhost:9868"
echo "  ResourceManager1 RPC: localhost:8030"
echo "  ResourceManager2 RPC: localhost:8031" 