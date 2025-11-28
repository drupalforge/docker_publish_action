FROM zilliz/attu:v2.3.10 AS attu
FROM quay.io/coreos/etcd:v3.5.5 AS etcd
FROM milvusdb/milvus:v2.4.1 AS milvus
FROM minio/minio:RELEASE.2023-03-20T20-16-18Z AS minio

FROM devpanel/php:8.3-base-ai

ARG APP_ROOT="/var/www/html"
ARG APACHE_RUN_USER="www"
ARG APACHE_RUN_GROUP="www"
ARG APACHE_COMMAND

# Copy application code
COPY . /app/

# PREPARE DIR FOR INSTALL
RUN sudo rm -rf $APP_ROOT
RUN sudo mkdir -p $APP_ROOT
RUN sudo cp -r /app/. $APP_ROOT/.
RUN sudo rm -rf /app
RUN sudo chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP $APP_ROOT
# SET UP GIT
RUN git config --global --add safe.directory $APP_ROOT

# Install supervisor and dependencies
RUN apt-get update && apt-get install -y \
    supervisor \
    python3-pip \
    curl \
    && pip3 install supervisord-dependent-startup --break-system-packages \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# INSTALL CUSTOM PACKAGE (PHP extensions, project-specific tasks, etc.)
RUN $APP_ROOT/.devpanel/custom_package_installer.sh

# Install Milvus stack components

# Install Milvus dependencies
RUN apt-get update && apt-get install -y \
    libaio1 \
    libopenblas0 \
    libgomp1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy entire Milvus directory structure to preserve paths
COPY --from=milvus /milvus /milvus

# Create Milvus data directory with proper permissions
RUN mkdir -p /var/lib/milvus && \
    chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /var/lib/milvus && \
    chmod +x /milvus/bin/milvus

# Update library path for Milvus libraries
RUN echo "/milvus/lib" > /etc/ld.so.conf.d/milvus.conf && ldconfig

# Copy etcd binaries
COPY --from=etcd /usr/local/bin/etcd /usr/local/bin/etcd
COPY --from=etcd /usr/local/bin/etcdctl /usr/local/bin/etcdctl

# Create etcd data directory
RUN mkdir -p /etcd && chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /etcd

# Copy MinIO binary from the correct location
COPY --from=minio /opt/bin/minio /usr/bin/minio

# Create MinIO data directory
RUN mkdir -p /minio_data && chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /minio_data

# Copy Attu Node.js application
COPY --from=attu /app /app
COPY --from=attu /usr/local/bin/node /usr/local/bin/node
COPY --from=attu /usr/local/lib/node_modules /usr/local/lib/node_modules

# Fix permissions for attu to write env-config.js
RUN chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /app/build

# Generate apache.conf from build arg
RUN mkdir -p /etc/supervisor/conf.d && \
    printf "[program:apache2]\ncommand=%s\nuser=%%(ENV_APACHE_RUN_USER)s\nautostart=true\nautorestart=true\nstdout_logfile=/var/log/apache2/supervisor.log\nstderr_logfile=/var/log/apache2/supervisor_err.log\n" "$APACHE_COMMAND" > /etc/supervisor/conf.d/apache.conf

# Copy Supervisor configs for all services
COPY .ddev/web-build/supervisor/attu.conf /etc/supervisor/conf.d/attu.conf
COPY .ddev/web-build/supervisor/dependent-startup.conf /etc/supervisor/conf.d/dependent-startup.conf
COPY .ddev/web-build/supervisor/etcd.conf /etc/supervisor/conf.d/etcd.conf
COPY .ddev/web-build/supervisor/milvus.conf /etc/supervisor/conf.d/milvus.conf
COPY .ddev/web-build/supervisor/minio.conf /etc/supervisor/conf.d/minio.conf

# Create data directories and set ownership for Milvus services
RUN mkdir -p /etcd /milvus_data /var/lib/milvus /minio_data && \
    chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /etcd /milvus_data /var/lib/milvus /minio_data

# Create supervisor log directory
RUN mkdir -p /var/log/supervisor

# Create entrypoint script to add hostnames at runtime
RUN printf '#!/bin/bash\nset -e\n# Modify /etc/hosts as root\nsed -i "/localhost/ s/\$/  etcd minio milvus attu/" /etc/hosts\n# Execute the command\nexec "\$@"\n' > /entrypoint.sh && chmod +x /entrypoint.sh

# Switch to root for entrypoint to modify /etc/hosts
USER root

ENTRYPOINT ["/entrypoint.sh"]

# Start Supervisor as the main process (supervisord will handle switching users)
CMD ["supervisord", "-n"]
