FROM php:8.2-apache

# Install necessary dependencies for Laravel and enable PHP extensions
RUN apt-get update && apt-get install -y \
    unzip \
    git \
    nano \
    libonig-dev \
    libzip-dev \
    libpq-dev \
    && docker-php-ext-install pdo mbstring zip pdo_pgsql pgsql \
    && docker-php-ext-enable pdo_pgsql pgsql

# Copy Composer from official Composer image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Enable Apache rewrite module for Laravel routing
RUN a2enmod rewrite

# Create a custom user and assign necessary permissions
ARG USER=daniel
ARG UID=1000
RUN useradd -m -u ${UID} -s /bin/bash ${USER} && \
    usermod -a -G www-data ${USER} && \
    chown -R ${USER}:${USER} /var/www/html

# Set appropriate file permissions for the Laravel directory
RUN chmod -R 755 /var/www/html

# Configure Apache to point to the Laravel /public directory for proper routing
RUN echo '<VirtualHost *:80>\n\
    ServerAdmin webmaster@localhost\n\
    DocumentRoot /var/www/html/public\n\
    <Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Set the working directory to the Laravel public folder
WORKDIR /var/www/html/public