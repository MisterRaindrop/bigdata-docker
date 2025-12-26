#!/usr/bin/env python3

import requests
import json
import pandas as pd
from pyiceberg.catalog import load_catalog

def get_token():
    response = requests.post(
        "http://localhost:8181/api/catalog/v1/oauth/tokens",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data={
            "grant_type": "client_credentials",
            "client_id": "root",
            "client_secret": "s3cr3t",
            "scope": "PRINCIPAL_ROLE:ALL"
        }
    )
    return response.json()["access_token"]

def create_namespace(token, catalog_name="polaris", namespace="test_ns"):
    response = requests.post(
        f"http://localhost:8181/api/catalog/v1/{catalog_name}/namespaces",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        json={
            "namespace": [namespace],
            "properties": {}
        }
    )
    print(f"Namespace creation: {response.status_code}")

def write_sample_data():
    catalog = load_catalog(
        "polaris",
        **{
            "type": "rest",
            "uri": "http://localhost:8181/api/catalog/v1",
            "credential": "root:s3cr3t",
            "warehouse": "polaris",
            "s3.endpoint": "http://localhost:9000",
            "s3.access-key-id": "minio_root",
            "s3.secret-access-key": "m1n1opwd",
            "s3.path-style-access": "true"
        }
    )

    df = pd.DataFrame({
        "id": [1, 2, 3, 4, 5],
        "name": ["Alice", "Bob", "Charlie", "David", "Eve"],
        "age": [25, 30, 35, 28, 32],
        "city": ["New York", "London", "Tokyo", "Paris", "Berlin"]
    })

    table = catalog.create_table(
        "test_ns.sample_table",
        schema={
            "type": "struct",
            "fields": [
                {"id": 1, "name": "id", "required": True, "type": "long"},
                {"id": 2, "name": "name", "required": True, "type": "string"},
                {"id": 3, "name": "age", "required": True, "type": "int"},
                {"id": 4, "name": "city", "required": True, "type": "string"}
            ]
        }
    )

    table.append(df)
    print("Data written successfully!")

if __name__ == "__main__":
    try:

        token = get_token()
        print("Token obtained successfully")

        create_namespace(token)

        write_sample_data()
    except Exception as e:
        print(f"Error: {e}")
