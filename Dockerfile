# Dockerfile for Cloud Run WordPress with ctf-petition-theme
FROM wordpress:6.5-php8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    less \
    vim \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Ensure Apache listens on $PORT (default 8080 in Cloud Run)
RUN sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's/80/${PORT}/g' /etc/apache2/ports.conf

# Copy custom scripts
COPY wp-setup.sh /usr/local/bin/wp-setup.sh
COPY custom-entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/wp-setup.sh /usr/local/bin/custom-entrypoint.sh

# Use Cloud Run's PORT
EXPOSE 8080
