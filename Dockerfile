ARG BASE_IMAGE=devpanel/php:8.3-base
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

ARG APP_ROOT="/var/www/html"
ARG APACHE_RUN_USER="www"
ARG APACHE_RUN_GROUP="www"

USER root
# PREPARE DIR FOR INSTALL
RUN rm -rf -- "$APP_ROOT"

# Copy application code
COPY --chown=${APACHE_RUN_USER}:${APACHE_RUN_GROUP} . ${APP_ROOT}/

# SET UP GIT
USER $USER
RUN git config --global --add safe.directory "$APP_ROOT"
