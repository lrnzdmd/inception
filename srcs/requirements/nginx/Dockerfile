FROM	debian:bullseye

RUN	apt-get update \
	&& apt-get install -y \
	nginx \
	openssl \
	gettext \
	&& rm -rf /var/lib/apt/lists/*

COPY	conf/nginx.conf /etc/nginx/templates/nginx.conf
COPY	tools/init.sh /usr/local/bin/init.sh

RUN	chmod +x /usr/local/bin/init.sh

EXPOSE	443

ENTRYPOINT ["init.sh"]
