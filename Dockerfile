# Stage 1: Build Stage
FROM php:8.2-fpm-alpine AS build

# Install build dependencies
RUN apk update && apk add --no-cache \
    build-base \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    freetype-dev \
    libzip-dev \
    zip \
    curl \
    unzip \
    git \
    bash \
    fcgi \
    oniguruma-dev \
    nodejs \
    npm

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) pdo pdo_mysql mbstring zip exif pcntl bcmath opcache

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set permissions for Laravel directories
RUN chown -R www-data:www-data /var/www

# Stage 2: Runtime Stage
FROM php:8.2-fpm-alpine AS runtime

# Install runtime dependencies (excluding build dependencies)
RUN apk --no-cache add \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    freetype-dev \
    libzip-dev \
    zip \
    curl \
    git \
    unzip \
    bash \
    fcgi \
    oniguruma-dev \
    nodejs \
    npm

# Install PHP extensions (no need to re-install, as they are already built)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) pdo pdo_mysql mbstring zip exif pcntl bcmath opcache

# Copy Composer binary from build stage
COPY --from=build /usr/local/bin/composer /usr/local/bin/composer

# Set permissions for Laravel directories
RUN chown -R www-data:www-data /var/www

# Switch to the www-data user
USER www-data

# Expose port 9000
EXPOSE 9000

# Start php-fpm server
CMD ["php-fpm"]
