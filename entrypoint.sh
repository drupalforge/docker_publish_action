#!/bin/bash
set -e

# Add service hostnames to /etc/hosts if not already present
for host in etcd minio milvus attu; do
  if grep -q "$host" /etc/hosts; then
    echo "$host found in /etc/hosts"
  elif timeout 2 getent hosts "$host" >/dev/null 2>&1; then
    echo "$host resolves via getent"
  else
    echo "Adding $host to /etc/hosts"
    if sed "/localhost/s/$/ $host/" /etc/hosts > /tmp/hosts && cat /tmp/hosts > /etc/hosts && rm /tmp/hosts; then
      echo "$host added successfully"
    else
      echo "Failed to add $host to /etc/hosts"
      exit 1
    fi
  fi
done

# Ensure Milvus, Minio, and Etcd volume directories exist
mkdir -p "$APP_ROOT/.devpanel/milvus/volumes/milvus" \
         "$APP_ROOT/.devpanel/milvus/volumes/minio" \
         "$APP_ROOT/.devpanel/milvus/volumes/etcd"

# Restore Milvus volumes from archive if present
if [ -f "$APP_ROOT/.devpanel/dumps/milvus.tgz" ]; then
  echo 'Restoring Milvus volumes from archive...'
  rm -rf "$APP_ROOT/.devpanel/milvus/volumes/*"
  tar xzf "$APP_ROOT/.devpanel/dumps/milvus.tgz" -C "$APP_ROOT/.devpanel/milvus/volumes"
  rm -f "$APP_ROOT/.devpanel/dumps/milvus.tgz"
fi

# Set ownership of Milvus volume directories
chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP "$APP_ROOT/.devpanel/milvus"

# Set Apache command from arguments (either from CMD or docker run override)
if [ $# -gt 0 ]; then
  export APACHE_COMMAND="$*"
  echo "Apache command set to: $APACHE_COMMAND"
else
  echo "WARNING: No command passed, Apache will not start via supervisor"
fi

# Start supervisord
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
