FROM	debian:bookworm

RUN	apt-get update \
	&& apt-get install -y \
	mariadb-server \
	&& rm -rf /var/lib/apt/lists/*

COPY	conf/my.cnf /etc/mysql/mariadb.conf.d/99-custom.cnf
COPY	tools/init.sh /usr/local/bin/init.sh

RUN	chmod +x /usr/local/bin/init.sh \
	&& mkdir -p /run/mysqld \
	&& chown -R mysql:mysql /run/mysqld /var/lib/mysql

EXPOSE	3306

ENTRYPOINT ["init.sh"]
