FROM	debian:bookworm

RUN	apt-get update \
	&& apt-get install -y \
	php8.2 php8.2-fpm php8.2-mysql wget \
	&& mkdir -p /var/www/html /run/php \
	&& wget -O /var/www/html/adminer.php https://www.adminer.org/latest.php 

COPY	tools/init.sh /usr/local/bin/init.sh
RUN	chmod +x /usr/local/bin/init.sh
RUN	sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

STOPSIGNAL SIGKILL

CMD ["init.sh"]