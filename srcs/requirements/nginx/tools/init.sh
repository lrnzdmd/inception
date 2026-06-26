#!/bin/sh

set -e

trap 'echo "[Nginx] ERROR: initialization failed."' EXIT

echo "[Nginx] Generating self signed SSL certificate."

mkdir -p /etc/nginx/ssl

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/key.pem \
	-out /etc/nginx/ssl/cert.pem \
	-subj "/CN=${DOMAIN_NAME}" \
	-addext "subjectAltName=DNS:${DOMAIN_NAME},DNS:bonus.${DOMAIN_NAME},DNS:adminer.${DOMAIN_NAME},DNS:kuma.${DOMAIN_NAME}"

echo "[Nginx] Certificate Generated."

envsubst '${DOMAIN_NAME}' < /etc/nginx/templates/nginx.conf > /etc/nginx/conf.d/default.conf

trap - EXIT

echo "[Nginx] Launching Nginx."

exec nginx -g "daemon off;"
