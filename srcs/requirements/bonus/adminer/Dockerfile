FROM	debian:bullseye

RUN	apt-get update \
	&& apt-get install -y \
	php7.4 php7.4-fpm php7.4-mysql wget \
	&& mkdir -p /var/www/html /run/php \
	&& wget -O /var/www/html/adminer.php https://www.adminer.org/latest.php 

COPY	tools/init.sh /usr/local/bin/init.sh
RUN	chmod +x /usr/local/bin/init.sh
RUN	sed -i 's|listen = /run/php/php7.4-fpm.sock|listen = 9000|' /etc/php/7.4/fpm/pool.d/www.conf

STOPSIGNAL SIGKILL

CMD ["init.sh"]
