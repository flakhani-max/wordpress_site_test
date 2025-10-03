#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------
# 0) Defaults & inputs
# ---------------------------------------------
PORT="${PORT:-8080}"                          # Cloud Run injects PORT
SITE_URL="${WP_URL:-http://127.0.0.1:${PORT}}" # Use Cloud Run URL or local
SITE_TITLE="${WP_TITLE:-CTF Landing Pages}"
ADMIN_USER="${WP_ADMIN_USER:-admin}"
ADMIN_PASS="${WP_ADMIN_PASS:-adminpass123}"
ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"
SITE_LANGUAGE="${WP_LANGUAGE:-en_US}"
SEARCH_ENGINE_VISIBILITY="${WP_SEARCH_ENGINE_VISIBILITY:-1}"  # 1 = visible, 0 = discourage indexing
MAILCHIMP_API_KEY="${MAILCHIMP_API_KEY:-}"
ACF_PRO_KEY="${ACF_PRO_KEY:-}"                 # pass via env/secret, do NOT hardcode

DOCROOT="/var/www/html"

# ---------------------------------------------
# 1) Make Apache listen on $PORT (Cloud Run)
# ---------------------------------------------
# ports.conf
if grep -qE '^Listen ' /etc/apache2/ports.conf; then
  sed -i "s/^Listen .*/Listen ${PORT}/" /etc/apache2/ports.conf
else
  echo "Listen ${PORT}" >> /etc/apache2/ports.conf
fi

# Any existing vhosts :80 -> :$PORT
if [ -d /etc/apache2/sites-available ]; then
  sed -i "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g" /etc/apache2/sites-available/*.conf || true
fi

# ---------------------------------------------
# 2) Ensure WP-CLI exists (if your image didn’t install it)
# ---------------------------------------------
if ! command -v wp >/dev/null 2>&1; then
  curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x /usr/local/bin/wp
fi

# ---------------------------------------------
# 3) Start Apache (the official entrypoint does setup too)
# ---------------------------------------------
/usr/local/bin/docker-entrypoint.sh apache2-foreground & pid=$!

# Wait for HTTP to be up (Apache bound to $PORT)
until curl -fsS "http://127.0.0.1:${PORT}/" >/dev/null; do
  echo "Waiting for Apache on port ${PORT}..."
  sleep 2
done

# ---------------------------------------------
# 4) Install / configure WordPress via WP-CLI
# ---------------------------------------------
# Wait until DB is reachable by WP (requires WORDPRESS_DB_* envs to be set)
i=0
until wp db check --path="$DOCROOT" --allow-root >/dev/null 2>&1; do
  i=$((i+1))
  if [ "$i" -gt 30 ]; then
    echo "Database not reachable after 60s. Check WORDPRESS_DB_* envs and Cloud SQL connection."
    exit 1
  fi
  echo "Waiting for DB..."
  sleep 2
done

# Install if not installed, otherwise noop
if ! wp core is-installed --path="$DOCROOT" --allow-root; then
  echo "Running wp core install..."
  wp core install \
    --path="$DOCROOT" \
    --url="$SITE_URL" \
    --title="$SITE_TITLE" \
    --admin_user="$ADMIN_USER" \
    --admin_password="$ADMIN_PASS" \
    --admin_email="$ADMIN_EMAIL" \
    --skip-email \
    --allow-root || true
fi

# Language
wp language core install "$SITE_LANGUAGE" --path="$DOCROOT" --allow-root || true
wp language core activate "$SITE_LANGUAGE" --path="$DOCROOT" --allow-root || true

# Options
wp option update blogname "$SITE_TITLE" --path="$DOCROOT" --allow-root
wp option update admin_email "$ADMIN_EMAIL" --path="$DOCROOT" --allow-root
wp option update blog_public "$SEARCH_ENGINE_VISIBILITY" --path="$DOCROOT" --allow-root

# IMPORTANT: don’t hardcode localhost; use SITE_URL
wp option update siteurl "$SITE_URL" --path="$DOCROOT" --allow-root
wp option update home "$SITE_URL" --path="$DOCROOT" --allow-root

# Ensure admin password stays synced with env if you change it
wp user update "$ADMIN_USER" --user_pass="$ADMIN_PASS" --path="$DOCROOT" --allow-root || true

# Core/theme/plugin updates (best-effort)
wp core update --path="$DOCROOT" --allow-root || true

# ACF Pro (only if you provided a valid key via env)
if [ -n "$ACF_PRO_KEY" ] && ! wp plugin is-installed advanced-custom-fields-pro --path="$DOCROOT" --allow-root; then
  wp plugin install "https://connect.advancedcustomfields.com/index.php?p=pro&a=download&k=${ACF_PRO_KEY}" \
    --activate --path="$DOCROOT" --allow-root || true
fi

# Mailchimp plugin
if ! wp plugin is-installed mailchimp-for-wp --path="$DOCROOT" --allow-root; then
  wp plugin install mailchimp-for-wp --activate --path="$DOCROOT" --allow-root || true
fi

# Custom petition plugin (activate if present)
if wp plugin is-installed wp-petition-mailchimp --path="$DOCROOT" --allow-root; then
  wp plugin activate wp-petition-mailchimp --path="$DOCROOT" --allow-root || true
fi

# Import ACF field group if the XML exists
if wp plugin is-installed advanced-custom-fields-pro --path="$DOCROOT" --allow-root && [ -f "$DOCROOT/acf-fields.xml" ]; then
  wp acf import "$DOCROOT/acf-fields.xml" --path="$DOCROOT" --allow-root || true
fi

# Set Mailchimp key if provided
if [ -n "$MAILCHIMP_API_KEY" ]; then
  wp option update mc4wp_api_key "$MAILCHIMP_API_KEY" --path="$DOCROOT" --allow-root || true
fi

# Activate custom theme
if wp theme is-installed ctf-landing-pages --path="$DOCROOT" --allow-root; then
  wp theme activate ctf-landing-pages --path="$DOCROOT" --allow-root || true
fi

# Remove default themes (keep only custom)
for theme in $(wp theme list --field=name --path="$DOCROOT" --allow-root); do
  if [ "$theme" != "ctf-landing-pages" ]; then
    wp theme delete "$theme" --path="$DOCROOT" --allow-root || true
  fi
done

# Remove default plugins Akismet and Hello Dolly
for plugin in akismet hello; do
  if wp plugin is-installed "$plugin" --path="$DOCROOT" --allow-root; then
    wp plugin delete "$plugin" --path="$DOCROOT" --allow-root || true
  fi
done

# Create an editor user if missing
if ! wp user get editor --path="$DOCROOT" --allow-root >/dev/null 2>&1; then
  wp user create editor editor@example.com --role=editor --user_pass=editorpass --path="$DOCROOT" --allow-root || true
fi

# Update all plugins/themes (best-effort)
wp plugin update --all --path="$DOCROOT" --allow-root || true
wp theme  update --all --path="$DOCROOT" --allow-root || true

# Fix perms (uploads etc.)
chown -R www-data:www-data "$DOCROOT/wp-content" || true

# Keep Apache in foreground
wait "$pid"
