#!/bin/sh

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

trap 'echo "[Wordpress] ERROR: initalization failed."' EXIT

while ! mysqladmin ping -h mariadb -u${MYSQL_USER} -p${MYSQL_PASSWORD} --silent; do
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
	
wp redis enable \
	--path=/var/www/html \
    	--allow-root

trap - EXIT

echo "[Wordpress] Launching php-fpm."

exec php-fpm8.2 --nodaemonize

