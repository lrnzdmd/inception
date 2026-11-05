FROM	debian:bookworm

RUN	apt-get update \
	&& apt-get install -y redis-server \
	&& rm -rf /var/lib/apt/lists/*

EXPOSE	6379

CMD	["redis-server", "--daemonize", "no", "--protected-mode", "no", "--maxmemory", "128mb", "--maxmemory-policy", "allkeys-lru"]
