FROM devpanel/php:8.3-base-rc

ARG APP_ROOT="/var/www/html"
ARG APACHE_RUN_USER="www"
ARG APACHE_RUN_GROUP="www"

# Copy application code
COPY . $APP_ROOT/

USER root

# PREPARE DIR FOR INSTALL
RUN chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP $APP_ROOT
# INSTALL CUSTOM PACKAGE
RUN $APP_ROOT/.devpanel/custom_package_installer.sh

USER ${USER}

# SET UP GIT
RUN git config --global --add safe.directory $APP_ROOT
