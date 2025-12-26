#!/bin/bash


docker exec -u root -it polaris-polaris-1 bash -c "
    microdnf install -y python3 python3-pip &&
    pip3 install pyiceberg pandas requests
"

echo "Dependencies installed in Polaris container"
