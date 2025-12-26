#!/bin/bash
docker exec -u root polaris-polaris-1 sh -c "
curl -L https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64 -o /tmp/jq && 
chmod +x /tmp/jq && 
mv /tmp/jq /usr/local/bin/jq
"
