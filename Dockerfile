FROM devpanel/php:8.3-base-ai

ARG APP_ROOT="/var/www/html"
ARG APACHE_RUN_USER="www"
ARG APACHE_RUN_GROUP="www"

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
# INSTALL CUSTOM PACKAGE
RUN $APP_ROOT/.devpanel/custom_package_installer.sh
