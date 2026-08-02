ARG BASE_IMAGE=devpanel/php:8.3-base
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

ARG APP_ROOT="/var/www/html"
ARG APACHE_RUN_USER="www"
ARG APACHE_RUN_GROUP="www"

ENV COMPOSER_HOME="${HOME}/.config/composer"

# SET UP GIT
RUN git config --global --add safe.directory "$APP_ROOT"

USER root

# PREPARE DIR FOR INSTALL
RUN rm -rf -- "$APP_ROOT"

# Copy application code
COPY --chown=${APACHE_RUN_USER}:${APACHE_RUN_GROUP} . ${APP_ROOT}/

# Install the PHP PostgreSQL extension.
RUN docker-php-ext-install pgsql

USER ${USER}
