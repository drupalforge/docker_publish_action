FROM zilliz/attu:v2.3.10 AS attu
FROM quay.io/coreos/etcd:v3.5.5 AS etcd
FROM milvusdb/milvus:v2.4.1 AS milvus
FROM minio/minio:RELEASE.2023-03-20T20-16-18Z AS minio

FROM devpanel/php:8.3-base-ai

ARG APP_ROOT="/var/www/html"
ARG APACHE_RUN_USER="www"
ARG APACHE_RUN_GROUP="www"
ARG APACHE_COMMAND

ENV DEBIAN_FRONTEND=noninteractive

# Suppress dpkg progress output
RUN echo 'Dpkg::Use-Pty "0";' | sudo tee /etc/apt/apt.conf.d/00usepty

# Copy application code from default context
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
RUN sudo apt-get update -qq && sudo apt-get install -y -qq \
    supervisor \
    python3-pip \
    curl \
    && sudo pip3 install supervisord-dependent-startup --break-system-packages

# INSTALL CUSTOM PACKAGE (PHP extensions, project-specific tasks, etc.)
RUN $APP_ROOT/.devpanel/custom_package_installer.sh

# Install Milvus stack components

# Install Milvus dependencies
RUN sudo apt-get update -qq && sudo apt-get install -y -qq \
    libaio1 \
    libopenblas0 \
    libgomp1

# Copy entire Milvus directory structure to preserve paths
COPY --from=milvus /milvus /milvus

# Create Milvus data directory with proper permissions
RUN sudo mkdir -p /var/lib/milvus && \
    sudo chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /var/lib/milvus && \
    sudo chmod +x /milvus/bin/milvus

# Update library path for Milvus libraries
RUN echo "/milvus/lib" | sudo tee /etc/ld.so.conf.d/milvus.conf && sudo ldconfig

# Copy etcd binaries
COPY --from=etcd /usr/local/bin/etcd /usr/local/bin/etcd
COPY --from=etcd /usr/local/bin/etcdctl /usr/local/bin/etcdctl

# Create etcd data directory
RUN sudo mkdir -p /etcd && sudo chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /etcd

# Copy MinIO binary from the correct location
COPY --from=minio /opt/bin/minio /usr/bin/minio

# Create MinIO data directory
RUN sudo mkdir -p /minio_data && sudo chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /minio_data

# Copy Attu Node.js application
COPY --from=attu /app /app
COPY --from=attu /usr/local/bin/node /usr/local/bin/node
COPY --from=attu /usr/local/lib/node_modules /usr/local/lib/node_modules

# Install yarn for Attu
RUN sudo apt-get update -qq && sudo apt-get install -y -qq yarnpkg && \
    sudo ln -sf /usr/bin/yarnpkg /usr/bin/yarn

# Enable Apache proxy modules and configure Attu proxy
RUN sudo a2enmod proxy proxy_http
COPY --from=docker_publish_action attu-proxy.conf /etc/apache2/conf-available/attu-proxy.conf
RUN sudo a2enconf attu-proxy

# Fix permissions for attu to write env-config.js
RUN sudo chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /app/build

# Copy supervisor configs
COPY --from=docker_publish_action supervisor/*.conf /etc/supervisor/
COPY --from=docker_publish_action supervisor/conf.d/* /etc/supervisor/conf.d/

# Generate apache supervisor config from template
RUN sudo sed -i "s|__APACHE_COMMAND__|${APACHE_COMMAND}|g" /etc/supervisor/conf.d/apache.conf.template && \
    sudo mv /etc/supervisor/conf.d/apache.conf.template /etc/supervisor/conf.d/apache.conf

# Create data directories and set ownership for Milvus services
RUN sudo mkdir -p /etcd /milvus_data /var/lib/milvus /minio_data && \
    sudo chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /etcd /milvus_data /var/lib/milvus /minio_data

# Create supervisor log directory
RUN sudo mkdir -p /var/log/supervisor

# Clean up apt cache and remove dpkg configuration used only for build
RUN sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* && sudo rm -f /etc/apt/apt.conf.d/00usepty

# Switch to root to run supervisord (it will handle user switching for individual services)
USER root

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
