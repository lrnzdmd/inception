FROM	debian:bookworm

RUN	apt-get update \
	&& apt-get install -y vsftpd \
	&& rm -rf /var/lib/apt/lists/*

COPY	tools/init.sh /usr/local/bin/init.sh
RUN	chmod +x /usr/local/bin/init.sh

EXPOSE	21 21000-21010

ENTRYPOINT ["init.sh"]
