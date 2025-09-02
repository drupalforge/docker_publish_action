FROM devpanel/php:8.3-base-ai

ARG DP_APP_ID
ARG DP_AI_VIRTUAL_KEY

# Application and service environment variables
ENV PHP_MEMORY_LIMIT="4096M"
ENV PHP_MAX_EXECUTION_TIME="600"
ENV PHP_MAX_INPUT_TIME="600"
ENV PHP_MAX_INPUT_VARS="3000"
ENV PHP_UPLOAD_MAX_FILESIZE="64M"
ENV PHP_POST_MAX_SIZE="64M"
ENV PHP_CLEAR_ENV="false"
ENV DP_APP_ID=$DP_APP_ID
ENV APP_ROOT="/var/www/html"
ENV WEB_ROOT="/var/www/html/web"
ENV CODES_USER_DATA_DIR="/var/www/html/.vscode"
ENV CODES_WORKING_DIR="/var/www/html"
ENV APACHE_RUN_USER="www"
ENV APACHE_RUN_GROUP="www"
ENV DB_HOST="mysql"
ENV DB_PORT="3306"
ENV DB_ROOT_PASSWORD="root"
ENV DB_NAME="drupaldb"
ENV DB_USER="user"
ENV DB_PASSWORD="password"
ENV DB_DRIVER="mysql"
ENV DP_AI_VIRTUAL_KEY=$DP_AI_VIRTUAL_KEY

# Copy application code
COPY . /app/

# PREPARE DIR FOR INSTALL
RUN sudo rm -rf $APP_ROOT && sudo mkdir -p $APP_ROOT
RUN sudo cp -r /app/. $APP_ROOT/.
RUN sudo chown -R www:www $APP_ROOT
RUN export && cd $APP_ROOT && ls -al
# SET UP GIT
RUN git config --global --add safe.directory $APP_ROOT
# INSTALL CUSTOM PACKAGE
RUN $APP_ROOT/.devpanel/custom_package_installer.sh
