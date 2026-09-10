FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    build-essential \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone https://github.com/louislam/uptime-kuma.git . \
    && git checkout 1.23.13

RUN npm run setup

EXPOSE 3001

CMD ["node", "server/server.js"]
