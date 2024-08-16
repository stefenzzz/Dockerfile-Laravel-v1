# Stage 1: Build Stage
FROM php:8.2-fpm-alpine AS build

# Install build dependencies
RUN apk --no-cache add \
    $PHPIZE_DEPS \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    freetype-dev \
    libzip-dev \
    oniguruma-dev \
    curl \
    git \
    unzip \
    bash \
    nodejs \
    npm

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) pdo pdo_mysql mbstring zip exif pcntl bcmath opcache

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Stage 2: Runtime Stage
FROM php:8.2-fpm-alpine AS runtime

# Install runtime dependencies (only essential packages)
RUN apk --no-cache add \
    libpng \
    libjpeg-turbo \
    libwebp \
    libxpm \
    freetype \
    libzip \
    oniguruma \
    zip \
    curl \
    bash \
    fcgi \
    nodejs \
    npm

# Copy the built PHP extensions and Composer-installed files from the build stage
COPY --from=build /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=build /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
COPY --from=build /usr/local/bin/composer /usr/local/bin/composer

# Copy the application code from the build stage
COPY --from=build /var/www /var/www

# Set permissions for Laravel directories
RUN chown -R www-data:www-data /var/www

# Switch to the www-data user
USER www-data

# Expose port 9000
EXPOSE 9000

# Start php-fpm server
CMD ["php-fpm"]
