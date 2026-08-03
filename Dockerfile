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
# If libpq build/link prerequisites are missing, install them temporarily,
# build pgsql, then purge the temporary dev dependencies.
RUN set -eux; \
    installed_pgsql_build_deps=0; \
    if ! command -v pg_config >/dev/null 2>&1; then \
      apt-get update; \
      apt-get install -y --no-install-recommends libpq-dev pkg-config; \
      installed_pgsql_build_deps=1; \
    elif ! ( \
      cat >/tmp/pqtest.c <<'EOF' && \
#include <libpq-fe.h>
int main(void){ return (int)PQlibVersion(); }
EOF
      cc /tmp/pqtest.c -o /tmp/pqtest $(pkg-config --cflags --libs libpq 2>/dev/null || echo -lpq) \
    ); then \
      apt-get update; \
      apt-get install -y --no-install-recommends libpq-dev pkg-config; \
      installed_pgsql_build_deps=1; \
    fi; \
    rm -f /tmp/pqtest.c /tmp/pqtest || true; \
    docker-php-ext-install pgsql; \
    if [ "$installed_pgsql_build_deps" -eq 1 ]; then \
      apt-get purge -y --auto-remove libpq-dev pkg-config; \
    fi; \
    rm -rf /var/lib/apt/lists/*

USER ${USER}
