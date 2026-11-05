#!/bin/sh

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

trap 'echo "[Wordpress] ERROR: initalization failed."' EXIT

# Bounded wait: mariadb is already healthy (depends_on condition), this only
# covers short races. After 30 attempts the script exits and Docker restarts it.
tries=0
until mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
	tries=$((tries + 1))
	if [ "$tries" -ge 30 ]; then
		echo "[Wordpress] Database unreachable, giving up."
		exit 1
	fi
	echo "[Wordpress] Waiting for the database to be up."
	sleep 2
done

echo "[Wordpress] Initializing wordpress container"

if [ ! -f "/var/www/html/wp-config.php" ]; then

	echo "[Wordpress] First execution detected, downloading and setting up wordpress."
	
	wp core download \
		--path=/var/www/html \
		--allow-root

	wp config create \
		--path=/var/www/html \
		--dbname=${MYSQL_DB} \
		--dbuser=${MYSQL_USER} \
		--dbpass=${MYSQL_PASSWORD} \
		--dbhost=mariadb \
		--allow-root

	wp core install \
		--path=/var/www/html \
		--url=https://${DOMAIN_NAME} \
		--title="Inception" \
		--admin_user=${WP_ADMIN_USER} \
		--admin_password=${WP_ADMIN_PASSWORD} \
		--admin_email=${WP_ADMIN_EMAIL} \
		--allow-root

	wp plugin install redis-cache --activate \
  		--path=/var/www/html \
   		--allow-root

	wp config set WP_REDIS_HOST redis \
 		--path=/var/www/html \
 		--allow-root

	wp config set WP_REDIS_PORT 6379 \
  		--path=/var/www/html \
  	 	--allow-root

	wp user create ${WP_USER} ${WP_USER_EMAIL} \
		--role=author \
		--user_pass=${WP_USER_PASSWORD} \
		--path=/var/www/html \
		--allow-root

	echo "[Wordpress] Installation and setup complete."

fi

# Site URL follows the Host header (including a non-default port), so the site
# keeps working if the NGINX published port is changed. wp-cli falls back to
# DOMAIN_NAME because it has no HTTP_HOST.
wp config set WP_HOME "'https://' . (\$_SERVER['HTTP_HOST'] ?? '${DOMAIN_NAME}')" \
	--raw \
	--path=/var/www/html \
	--allow-root

wp config set WP_SITEURL "'https://' . (\$_SERVER['HTTP_HOST'] ?? '${DOMAIN_NAME}')" \
	--raw \
	--path=/var/www/html \
	--allow-root

# Comments from logged-in users are published without manual approval.
wp option update comment_previously_approved 0 \
	--path=/var/www/html \
	--allow-root

wp redis enable \
	--path=/var/www/html \
    	--allow-root

chown -R www-data:www-data /var/www/html

trap - EXIT

echo "[Wordpress] Launching php-fpm."

exec php-fpm8.2 --nodaemonize

