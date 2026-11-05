#!/bin/sh

set -e

FTP_PASSWORD=$(cat /run/secrets/ftp_password)
FTP_PASV_ADDRESS=${FTP_PASV_ADDRESS:-127.0.0.1}

trap 'echo "[FTP] ERROR: initialization failed."' EXIT

# The FTP user shares uid/gid 33 with www-data (same ids used by php-fpm in the
# wordpress container), so files uploaded via FTP are owned by www-data and
# WordPress can manage them, and vice versa.
if ! id "${FTP_USER}" > /dev/null 2>&1; then
	echo "[FTP] Creating user ${FTP_USER}."
	useradd -o -u 33 -g 33 -d /var/www/html -s /bin/bash "${FTP_USER}"
fi
echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd

mkdir -p /var/run/vsftpd/empty

cat > /etc/vsftpd.conf << CONF
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
local_root=/var/www/html
chroot_local_user=YES
allow_writeable_chroot=YES
userlist_enable=YES
userlist_deny=NO
userlist_file=/etc/vsftpd.userlist
pasv_enable=YES
pasv_address=${FTP_PASV_ADDRESS}
pasv_min_port=21000
pasv_max_port=21010
secure_chroot_dir=/var/run/vsftpd/empty
CONF

echo "${FTP_USER}" > /etc/vsftpd.userlist

trap - EXIT

echo "[FTP] Launching vsftpd (passive address: ${FTP_PASV_ADDRESS})."
exec vsftpd /etc/vsftpd.conf
