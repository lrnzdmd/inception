*This project has been created as part of the 42 curriculum by lde-medi.*

# Inception

## Description

Inception is a system administration project built around Docker. The goal is to set up a small infrastructure composed of multiple services, each running in its own container, orchestrated with Docker Compose inside a virtual machine.

The mandatory stack consists of NGINX as the sole entrypoint with TLS, WordPress with php-fpm, and MariaDB. Bonus services include Redis, FTP, Adminer, a static website, and Portainer.

## Instructions

### Prerequisites

- A Debian VM with Docker and Docker Compose installed
- The `secrets/` directory populated with password files (see `DEV_DOC.md`)
- `/etc/hosts` configured with `lde-medi.42.fr` pointing to `127.0.0.1`

### Usage

```bash
make        # build and start all services
make down   # stop all services
make fclean # stop all services and remove all data
```

## Project description

The infrastructure runs entirely inside Docker containers managed by Docker Compose. Each service has its own Dockerfile built from Debian Bullseye. No pre-made images are used except for the base OS.

### Design choices

**Virtual Machines vs Docker** — VMs virtualize an entire operating system including the kernel, making them heavier and slower to start. Docker containers share the host kernel and isolate only the user space, making them lighter and faster. VMs offer stronger isolation; containers offer better resource efficiency.

**Secrets vs Environment Variables** — environment variables are visible to any process in the container and can be leaked through logs or inspection. Docker secrets are mounted as files in `/run/secrets/` with restricted permissions, making them significantly harder to expose accidentally. All passwords in this project use secrets; only non-sensitive values use environment variables.

**Docker Network vs Host Network** — host network mode removes isolation and exposes all container ports directly on the host interface, which is a security risk. A Docker bridge network creates an isolated virtual network where containers communicate by service name, and only explicitly declared ports are reachable from outside.

**Docker Volumes vs Bind Mounts** — bind mounts directly expose a host directory path inside the container, creating a tight coupling to the host filesystem structure. Named volumes are managed by Docker and are more portable. This project uses named volumes backed by specific host paths to satisfy the subject requirement of storing data under `~/data/`.

## Resources

- Docker documentation: https://docs.docker.com
- NGINX documentation: https://nginx.org/en/docs
- WordPress CLI documentation: https://wp-cli.org
- MariaDB documentation: https://mariadb.com/kb/en
- php-fpm documentation: https://www.php.net/manual/en/install.fpm.php
- Redis documentation: https://redis.io/docs

**AI usage** — Claude (Anthropic) was used to help write this README and to assist in debugging by parsing container logs and identifying configuration errors.
