#!/bin/sh
set -e


API_HOST=${API_HOST:-http://localhost:8181}
REALM=${REALM:-POLARIS}
CATALOG_NAME=${CATALOG_NAME:-polaris}
NS_NAME=${NS_NAME:-public}
ROOT_CLIENT_ID=${ROOT_CLIENT_ID:-root}
ROOT_CLIENT_SECRET=${ROOT_CLIENT_SECRET:-s3cr3t}
S3_LOCATION=${S3_LOCATION:-s3://bucket123}
S3_ROLE_ARN=${S3_ROLE_ARN:-arn:aws:iam::000000000000:role/dummy}
S3_USER_ARN=${S3_USER_ARN:-arn:aws:iam::000000000000:user/dummy}
S3_REGION=${S3_REGION:-us-west-2}

need() { command -v "$1" >/dev/null 2>&1 || { echo "缺少命令: $1"; exit 1; }; }
need curl
need jq

get_token() {
  curl -s -X POST "$API_HOST/api/catalog/v1/oauth/tokens" \
    -d grant_type=client_credentials \
    -d client_id="$ROOT_CLIENT_ID" \
    -d client_secret="$ROOT_CLIENT_SECRET" \
    -d scope=PRINCIPAL_ROLE:ALL | jq -r '.access_token'
}

create_catalog() {
  TOKEN="$1"
  PAYLOAD=$(cat <<JSON
{
  "catalog": {
    "name": "$CATALOG_NAME",
    "type": "INTERNAL",
    "readOnly": false,
    "properties": { "default-base-location": "$S3_LOCATION" },
    "storageConfigInfo": {
      "storageType": "S3",
      "allowedLocations": ["$S3_LOCATION"],
      "roleArn": "$S3_ROLE_ARN",
      "userArn": "$S3_USER_ARN",
      "region": "$S3_REGION"
    }
  }
}
JSON
)
  CODE=$(curl -s -o /tmp/cat_resp.json -w "%{http_code}" -X POST "$API_HOST/api/management/v1/catalogs" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Polaris-Realm: $REALM" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")
  if [ "$CODE" = "201" ] || [ "$CODE" = "409" ]; then
    echo "catalog $CATALOG_NAME ok (code $CODE)"
  else
    echo "catalog 创建失败 code=$CODE"; cat /tmp/cat_resp.json; exit 1
  fi
}

create_namespace() {
  TOKEN="$1"

  create_catalog "$TOKEN"
  CODE=$(curl -s -o /tmp/ns_resp.json -w "%{http_code}" -X POST "$API_HOST/api/catalog/v1/$CATALOG_NAME/namespaces" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "Polaris-Realm: $REALM" \
    -d '{"namespace":["'"$NS_NAME"'"],"properties":{}}')
  if [ "$CODE" -ge 400 ]; then
    echo "namespace 创建失败 code=$CODE"; cat /tmp/ns_resp.json; exit 1
  else
    echo "namespace $NS_NAME ok (code $CODE)"
  fi
}

list_catalogs() {
  TOKEN="$1"
  curl -s -H "Authorization: Bearer $TOKEN" -H "Polaris-Realm: $REALM" \
    "$API_HOST/api/management/v1/catalogs" | jq .
}

list_namespaces() {
  TOKEN="$1"
  curl -s -H "Authorization: Bearer $TOKEN" -H "Polaris-Realm: $REALM" \
    "$API_HOST/api/catalog/v1/$CATALOG_NAME/namespaces" | jq .
}

case "$1" in
  create-catalog)
    TOKEN=$(get_token); create_catalog "$TOKEN"
    ;;
  create-namespace)
    TOKEN=$(get_token); create_namespace "$TOKEN"
    ;;
  list-catalogs)
    TOKEN=$(get_token); list_catalogs "$TOKEN"
    ;;
  list-namespaces)
    TOKEN=$(get_token); list_namespaces "$TOKEN"
    ;;
  *)
    echo "use: $0 {create-catalog|create-namespace|list-catalogs|list-namespaces}"
    echo "overwrite: API_HOST REALM CATALOG_NAME NS_NAME ROOT_CLIENT_ID ROOT_CLIENT_SECRET"
    echo "                 S3_LOCATION S3_ROLE_ARN S3_USER_ARN S3_REGION"
    exit 1
    ;;
esac