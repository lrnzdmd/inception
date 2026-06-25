FROM	debian:bullseye

RUN	apt-get update \
	&& apt-get install -y \
	php7.4 \
	php7.4-fpm \
	php7.4-mysql \
	php7.4-curl \
	php7.4-gd \
	php7.4-mbstring \
	php7.4-xml \
	php7.4-zip \
	mariadb-client \
	wget \
	&& rm -rf /var/lib/lists/*

RUN wget -O /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp
    
RUN sed -i 's|listen = /run/php/php7.4-fpm.sock|listen = 9000|' /etc/php/7.4/fpm/pool.d/www.conf

COPY	conf/www.conf /etc/php/8.3/fpm/pool.d/www.conf
COPY	tools/init.sh /usr/local/bin/init.sh

RUN	chmod +x /usr/local/bin/init.sh \
	&& mkdir -p /run/php \
	&& chown -R www-data:www-data /run/php

EXPOSE 9000

ENTRYPOINT ["init.sh"]

