ARG BASE_IMAGE=devpanel/php:8.3-base-rc
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

ARG APP_ROOT="/var/www/html"
ARG APACHE_RUN_USER="www"
ARG APACHE_RUN_GROUP="www"

# Copy application code
COPY . /app/

USER root
# PREPARE DIR FOR INSTALL
RUN rm -rf -- "$APP_ROOT" && \
    mkdir -p "$APP_ROOT" && \
    cp -r /app/. "$APP_ROOT"/. && \
    rm -rf -- /app && \
    chown -R "$APACHE_RUN_USER":"$APACHE_RUN_GROUP" "$APP_ROOT"
# SET UP GIT
USER $USER
RUN git config --global --add safe.directory "$APP_ROOT"
