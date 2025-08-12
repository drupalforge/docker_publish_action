FROM devpanel/php:8.3-base

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
