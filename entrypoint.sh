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

# Set Apache command from arguments (either from CMD or docker run override)
if [ $# -gt 0 ]; then
  export APACHE_COMMAND="$*"
  echo "Apache command set to: $APACHE_COMMAND"
else
  echo "WARNING: No command passed, Apache will not start via supervisor"
fi

# Start supervisord
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
