FROM devpanel/php:8.3-base

# Copy application code
COPY . /app/

# Prepare application root and permissions
RUN sudo rm -rf $APP_ROOT && \
    sudo mkdir -p $APP_ROOT && \
    sudo cp -r /app/. $APP_ROOT/. && \
    sudo chown -R www:www $APP_ROOT && \
    git config --global --add safe.directory $APP_ROOT && \
    $APP_ROOT/.devpanel/custom_package_installer.sh && \
    $APP_ROOT/.devpanel/init.sh

# Add any additional setup steps as needed
