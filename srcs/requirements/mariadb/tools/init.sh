#!/bin/sh

set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ADMIN_PASSWORD=$(cat /run/secrets/db_admin_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

trap 'echo "[MariaDB] ERROR: initialization ended unexpectedly."' EXIT

echo "[MariaDB] Starting database container."

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "[MariaDB] First execution detected, initializing datadir."
	mariadb_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
	echo "[MariaDB] Datadir initialized successfully."
fi

echo "[MariaDB] Users and database config..."

mariadbd --silent-startup --user=mysql --bootstrap << EOF

FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS ${MYSQL_DB};

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'%';

CREATE USER IF NOT EXISTS '${MYSQL_ADMIN_USER}'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_ADMIN_USER}'@'%' WITH GRANT OPTION;

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

FLUSH PRIVILEGES;
EOF

echo "[MariaDB] Users and database configured correctly, launching server."

trap - EXIT

exec mariadbd --silent-startup --user=mysql
