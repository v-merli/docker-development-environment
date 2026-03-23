FROM php:7.3-fpm

# Install system dependencies and security updates
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libmagickwand-dev \
    supervisor \
    zip \
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions required for Laravel
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Install Redis extension
RUN pecl install redis-5.3.7 && docker-php-ext-enable redis

# Install Imagick extension
RUN pecl install imagick && docker-php-ext-enable imagick

# Install Xdebug 2.x (compatibile con PHP 7.3)
RUN pecl install xdebug-2.9.8 && docker-php-ext-enable xdebug

# Configure Xdebug 2.x
RUN echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_connect_back=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.idekey=VSCODE" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node.js (build argument)
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Create supervisor log directory
RUN mkdir -p /var/log/supervisor

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

# Create npm cache directory with proper permissions
RUN mkdir -p /var/www/.npm && chown -R www-data:www-data /var/www/.npm

# Create composer directories with proper permissions
RUN mkdir -p /var/www/.config/composer /var/www/.cache/composer && chown -R www-data:www-data /var/www/.config /var/www/.cache

USER www-data

# Install Laravel installer globally
RUN composer global require laravel/installer

# Add Composer global bin to PATH
ENV PATH="/var/www/.config/composer/vendor/bin:${PATH}"
