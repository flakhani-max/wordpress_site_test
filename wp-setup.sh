
#!/bin/bash
set -e





# --- Customizable settings via environment variables ---
SITE_URL="${WP_URL:-http://localhost}"
SITE_TITLE="${WP_TITLE:-CTF Landing Pages}"
ADMIN_USER="${WP_ADMIN_USER:-admin}"
ADMIN_PASS="${WP_ADMIN_PASS:-adminpass123}"
ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"
SITE_LANGUAGE="${WP_LANGUAGE:-en_US}"
SEARCH_ENGINE_VISIBILITY="${WP_SEARCH_ENGINE_VISIBILITY:-1}"

# Wait for WordPress to be ready
until wp core is-installed --allow-root; do
  echo "Waiting for WordPress to be installed..."
  sleep 2
  wp core install \
    --url="$SITE_URL" \
    --title="$SITE_TITLE" \
    --admin_user="$ADMIN_USER" \
    --admin_password="$ADMIN_PASS" \
    --admin_email="$ADMIN_EMAIL" \
    --skip-email \
    --allow-root || true
done


# Set site language
wp language core install "$SITE_LANGUAGE" --allow-root || true
wp language core activate "$SITE_LANGUAGE" --allow-root || true


# Update site title, admin email, and search engine visibility (in case of changes)
wp option update blogname "$SITE_TITLE" --allow-root
wp option update admin_email "$ADMIN_EMAIL" --allow-root
wp option update blog_public "$SEARCH_ENGINE_VISIBILITY" --allow-root


# Update admin user password (in case of changes)
wp user update "$ADMIN_USER" --user_pass="$ADMIN_PASS" --allow-root



# Update WordPress core, plugins, and themes
wp core update --allow-root || true
wp plugin update --all --allow-root || true
wp theme update --all --allow-root || true


# Install and activate ACF Pro with license key
if ! wp plugin is-installed advanced-custom-fields-pro --allow-root; then
  wp plugin install https://connect.advancedcustomfields.com/index.php?p=pro&a=download&k=NGIzMjdmZWQ3ZTdmNzM2MjRjZTBmOGM2ZTJkMTFkOTJiMTdmZjk4MmRjZWQyODAxY2Q1Mjli --activate --allow-root
fi


# Install and activate Mailchimp SDK plugin
if ! wp plugin is-installed mailchimp-for-wp --allow-root; then
  wp plugin install mailchimp-for-wp --activate --allow-root
fi


# Activate custom petition Mailchimp plugin
if wp plugin is-installed wp-petition-mailchimp --allow-root; then
  wp plugin activate wp-petition-mailchimp --allow-root
fi


# Import ACF field group (if not already imported)
if wp plugin is-installed advanced-custom-fields-pro --allow-root; then
  wp acf import /var/www/html/acf-fields.xml --allow-root || true
fi


# Set Mailchimp API key if provided (example: from env var)
if [ ! -z "$MAILCHIMP_API_KEY" ]; then
  wp option update mc4wp_api_key "$MAILCHIMP_API_KEY" --allow-root
fi



# Activate the custom theme
wp theme activate ctf-landing-pages --allow-root

# Remove all default themes except the custom one
for theme in $(wp theme list --field=name --allow-root); do
  if [ "$theme" != "ctf-landing-pages" ]; then
    wp theme delete "$theme" --allow-root || true
  fi
done

# Remove default plugins Akismet and Hello Dolly
for plugin in akismet hello; do
  if wp plugin is-installed "$plugin" --allow-root; then
    wp plugin delete "$plugin" --allow-root || true
  fi
done

# Create an additional user (editor: editor/editorpass)
if ! wp user get editor --allow-root > /dev/null 2>&1; then
  wp user create editor editor@example.com --role=editor --user_pass=editorpass --allow-root
fi


# Run any theme activation hooks (optional)
wp eval-file /var/www/html/wp-content/themes/ctf-landing-pages/activate-theme.php --allow-root || true


# (No lock file, always runs)
