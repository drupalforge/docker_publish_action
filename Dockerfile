FROM zilliz/attu:v2.3.10 AS attu
FROM quay.io/coreos/etcd:v3.5.5 AS etcd
FROM milvusdb/milvus:v2.4.1 AS milvus
FROM minio/minio:RELEASE.2023-03-20T20-16-18Z AS minio

FROM devpanel/php:8.3-base

USER root

ARG DEBIAN_FRONTEND=noninteractive

# Suppress dpkg progress output
RUN echo 'Dpkg::Use-Pty "0";' > /etc/apt/apt.conf.d/00usepty

# Update apt repository information
RUN apt-get update -qq

# INSTALL CUSTOM PACKAGES (PHP extensions, project-specific tasks, etc.)
RUN apt-get install -y -qq jq libavif-dev nano npm && \
    docker-php-ext-configure gd --with-avif --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install gd && \
    for pkg in $(apt-cache depends libavif-dev | grep '^\s*Depends:' | grep -o 'libavif[^, ]*'); do \
        apt-mark manual "$pkg"; \
    done && \
    apt-get purge -y -qq libavif-dev && \
    apt-get autoremove -y -qq && \
    pecl update-channels && \
    printf '' | pecl install apcu && \
    echo 'extension=apcu.so' > /usr/local/etc/php/conf.d/apcu.ini && \
    pecl install uploadprogress && \
    echo 'extension=uploadprogress.so' > /usr/local/etc/php/conf.d/uploadprogress.ini

# Install supervisor and dependencies
RUN apt-get install -y -qq supervisor python3-pip curl && \
    pip3 install supervisord-dependent-startup --break-system-packages

# Install Milvus dependencies
RUN apt-get install -y -qq libaio1t64 libopenblas0 libgomp1 && \
    LIBAIO_LIBDIR=$(dpkg-architecture -q DEB_HOST_MULTIARCH) && \
    ln -s /usr/lib/$LIBAIO_LIBDIR/libaio.so.1t64 /usr/lib/$LIBAIO_LIBDIR/libaio.so.1

# Install yarn for Attu
RUN apt-get install -y -qq yarnpkg && \
    ln -sf /usr/bin/yarnpkg /usr/bin/yarn

# Clean up apt cache and remove dpkg configuration used only for build
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && rm -f /etc/apt/apt.conf.d/00usepty

# Copy Attu Node.js application
COPY --from=attu /app /app
COPY --from=attu /usr/local/bin/node /usr/local/bin/node
COPY --from=attu /usr/local/lib/node_modules /usr/local/lib/node_modules
# Copy etcd binaries
COPY --from=etcd /usr/local/bin/etcd /usr/local/bin/etcd
COPY --from=etcd /usr/local/bin/etcdctl /usr/local/bin/etcdctl
# Copy entire Milvus directory structure to preserve paths
COPY --from=milvus /milvus /milvus
# Copy MinIO binary
COPY --from=minio /opt/bin/minio /usr/bin/minio

# Update library path for Milvus libraries
RUN echo "/milvus/lib" > /etc/ld.so.conf.d/milvus.conf && \
    ldconfig && \
    chmod +x /milvus/bin/milvus

# Enable Apache proxy modules and configure Attu proxy
RUN a2enmod proxy proxy_http proxy_wstunnel headers substitute
COPY --from=docker_publish_action attu-proxy.conf /etc/apache2/conf-available/attu-proxy.conf
RUN a2enconf attu-proxy

# Copy supervisor configs
COPY --from=docker_publish_action supervisor/*.conf /etc/supervisor/
COPY --from=docker_publish_action supervisor/conf.d/* /etc/supervisor/conf.d/

# Create supervisor log directory
RUN mkdir -p /var/log/supervisor

# Fix Apache mutex issue in Docker and fix apache-start.sh script
RUN grep -q '^Mutex ' /templates/apache2.conf || echo 'Mutex file:/var/run/apache2' >> /templates/apache2.conf && \
    grep -q '^ServerName ' /templates/apache2.conf || echo 'ServerName localhost' >> /templates/apache2.conf && \
    sed -i 's|/bin/bash source ~/.bashrc|source ~/.bashrc|' /scripts/apache-start.sh

ARG APP_ROOT=/var/www/html
ARG APACHE_RUN_USER=www
ARG APACHE_RUN_GROUP=www
ARG DP_HOSTNAME=localhost
ARG CODES_ENABLE=no
ARG WEB_ROOT=/var/www/html/web

# Fix permissions for attu to write env-config.js and create symlinks for Milvus volumes
RUN cd /app && yarn install && \
    chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP build && \
    ln -sf "$APP_ROOT/.devpanel/milvus/volumes/etcd" /etcd && \
    ln -sf "$APP_ROOT/.devpanel/milvus/volumes/milvus" /var/lib/milvus && \
    rm -rf "$APP_ROOT"

# Copy application code from default context
COPY . "$APP_ROOT/"
RUN chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP "$APP_ROOT"

USER ${USER}

# SET UP GIT
RUN git config --global --add safe.directory $APP_ROOT

ENV APP_ROOT=${APP_ROOT}
ENV APACHE_RUN_USER=${APACHE_RUN_USER}
ENV APACHE_RUN_GROUP=${APACHE_RUN_GROUP}
ENV DP_HOSTNAME=${DP_HOSTNAME}
ENV CODES_ENABLE=${CODES_ENABLE}
ENV WEB_ROOT=${WEB_ROOT}
