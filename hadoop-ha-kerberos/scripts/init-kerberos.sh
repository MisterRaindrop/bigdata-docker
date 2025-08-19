#!/usr/bin/env bash
set -euo pipefail

: "${KERBEROS_REALM:=EXAMPLE.COM}"
: "${KERBEROS_ADMIN_PASSWORD:=adminpassword}"

export DEBIAN_FRONTEND=noninteractive

echo "[1/5] Install MIT Kerberos packages..."
apt-get update -qq
apt-get install -y -qq krb5-kdc krb5-admin-server krb5-user >/dev/null

# /etc/krb5.conf 已由宿主机挂载，无需覆盖

cat >/etc/krb5kdc/kdc.conf <<EOF
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88
[realms]
 ${KERBEROS_REALM} = {
  database_name = /var/lib/krb5kdc/principal
  admin_keytab = /etc/krb5kdc/kadm5.keytab
  acl_file = /etc/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  key_stash_file = /etc/krb5kdc/stash
  max_life = 1d
  max_renewable_life = 7d
 }
EOF

echo "*/admin@${KERBEROS_REALM} *" >/etc/krb5kdc/kadm5.acl

echo "[2/5] Create Kerberos database..."
echo -e "${KERBEROS_ADMIN_PASSWORD}\n${KERBEROS_ADMIN_PASSWORD}" | krb5_newrealm

kadmin.local -q "addprinc -pw ${KERBEROS_ADMIN_PASSWORD} root/admin"

mkdir -p /keytabs

# Helper to add principals and aggregate into role keytabs
add_to_keytab() {
  local princ="$1"; local keytab="$2"
  echo "  -> ${princ} -> ${keytab}"
  kadmin.local -q "addprinc -randkey ${princ}"
  kadmin.local -q "ktadd -k ${keytab} ${princ}"
}

echo "[3/5] Create service principals and aggregate keytabs..."
# NameNode principals into nn.keytab
add_to_keytab "nn/namenode1@${KERBEROS_REALM}" "/keytabs/nn.keytab"
add_to_keytab "nn/namenode2@${KERBEROS_REALM}" "/keytabs/nn.keytab"

# DataNode principals into dn.keytab
for host in datanode1 datanode2 datanode3; do
  add_to_keytab "dn/${host}@${KERBEROS_REALM}" "/keytabs/dn.keytab"
done

# JournalNode (optional) into jn.keytab
for host in journalnode1 journalnode2 journalnode3; do
  add_to_keytab "jtn/${host}@${KERBEROS_REALM}" "/keytabs/jn.keytab" || true
done

# ResourceManager into rm.keytab
add_to_keytab "rm/resourcemanager1@${KERBEROS_REALM}" "/keytabs/rm.keytab"
add_to_keytab "rm/resourcemanager2@${KERBEROS_REALM}" "/keytabs/rm.keytab"

# NodeManager into nm.keytab
for host in datanode1 datanode2 datanode3; do
  add_to_keytab "nm/${host}@${KERBEROS_REALM}" "/keytabs/nm.keytab" || true
done

# HTTP SPNEGO for web UIs into http.keytab
for host in namenode1 namenode2 datanode1 datanode2 datanode3 resourcemanager1 resourcemanager2 journalnode1 journalnode2 journalnode3; do
  add_to_keytab "HTTP/${host}@${KERBEROS_REALM}" "/keytabs/http.keytab"
done

chmod 640 /keytabs/*.keytab || true

echo "[4/5] Start KDC and Admin services..."
service krb5-kdc start
service krb5-admin-server start

echo "[5/5] Kerberos initialization completed."