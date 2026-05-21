FROM debian:bullseye

RUN apt-get update && apt-get install -y curl \
    && mkdir -p /portainer \
    && curl -L https://github.com/portainer/portainer/releases/download/2.21.5/portainer-2.21.5-linux-amd64.tar.gz \
    | tar -xz -C /portainer --strip-components=1

EXPOSE 9000

CMD ["/portainer/portainer"]
