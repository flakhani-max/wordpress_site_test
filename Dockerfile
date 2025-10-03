# Dockerfile for local WordPress development with ctf-petition-theme
FROM wordpress:6.5-php8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    less \
    vim \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# For development, use volume mounts for live editing. Uncomment these lines for production builds.
# COPY ./wp-content/themes/ctf-landing-pages /var/www/html/wp-content/themes/ctf-landing-pages
# COPY ./wp-content/plugins/ /var/www/html/wp-content/plugins/

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Expose port 80
EXPOSE 80


# Place custom setup and entrypoint scripts
COPY wp-setup.sh /usr/local/bin/wp-setup.sh
COPY custom-entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/wp-setup.sh /usr/local/bin/custom-entrypoint.sh
