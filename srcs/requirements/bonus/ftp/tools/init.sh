#!/bin/sh

set -e

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

if ! id ${FTP_USER} > /dev/null 2>&1; then
    adduser --disabled-password --gecos "" ${FTP_USER}
    echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
fi

mkdir -p /var/run/vsftpd/empty

cat > /etc/vsftpd.conf << EOF
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_root=/var/www/html
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=21000
pasv_max_port=21010
secure_chroot_dir=/var/run/vsftpd/empty
EOF

echo "[FTP] Launching vsftpd."
exec vsftpd /etc/vsftpd.conf
