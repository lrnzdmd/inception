*This project has been created as part of the 42 curriculum by lde-medi.*

# Inception

## Description

Inception is a system administration project built around Docker. The goal is to set up a small infrastructure composed of multiple services, each running in its own container, orchestrated with Docker Compose inside a virtual machine.

The mandatory stack consists of NGINX as the sole entrypoint with TLS, WordPress with php-fpm, and MariaDB. Bonus services include Redis, FTP, Adminer, a static website, and Uptime Kuma.

## Instructions

### Prerequisites

- A VM with Docker and Docker Compose installed
- A `secrets/` directory in the root of the project populated with password files (see `DEV_DOC.md`)
- A .env file in srcs/ with the environment variables needed (see `DEV_DOC.md`)
- `/etc/hosts` configured with `lde-medi.42.fr`, `bonus.lde-medi.42.fr`, `adminer.lde-medi.42.fr` and `kuma.lde-medi.42.fr` pointing to `127.0.0.1`

### Usage

```bash
make all       #Create data directories and launch the stack (default)
make setup     #Create data directories only
make up        #Build and start all containers in background
make down      #Stop and remove containers (volumes preserved)
make stop      #Stop containers without removing them
make start     #Restart containers stopped with 'stop'
make logs      #Follow logs of all containers in real time
make status    #Show status of all containers
make clean     #Remove containers, volumes and images
make fclean    #clean + delete data directories + docker system prune
make re        #fclean + all (full rebuild from scratch)
make help      #Show this help message
```

## Project description

The infrastructure runs entirely inside Docker containers managed by Docker Compose. Each service has its own Dockerfile built from Debian Bookworm. No pre-made images are used except for the base OS.

### Sources included in the project

| Path | Content |
|---|---|
| `Makefile` | Creates the data directories and drives Docker Compose (build, start, stop, clean) |
| `srcs/docker-compose.yml` | Services, named volumes, network and secrets definitions |
| `srcs/requirements/mariadb/` | MariaDB image: config (`my.cnf`) and init script creating the database and users |
| `srcs/requirements/wordpress/` | WordPress + php-fpm image: pool config and init script installing WordPress with WP-CLI |
| `srcs/requirements/nginx/` | NGINX image: TLS-only virtual hosts and init script generating a self-signed certificate |
| `srcs/requirements/bonus/redis/` | Redis object cache used by WordPress |
| `srcs/requirements/bonus/ftp/` | vsftpd server giving access to the WordPress files volume |
| `srcs/requirements/bonus/static/` | Static HTML/CSS website served by busybox httpd |
| `srcs/requirements/bonus/adminer/` | Adminer (php-fpm) for database management |
| `srcs/requirements/bonus/uptime-kuma/` | Uptime Kuma, a monitoring dashboard to check that every service is up |

Each container runs its main process in the foreground as PID 1 (via `exec` in the init scripts). Services whose process does not handle `SIGTERM` as PID 1 (busybox httpd, vsftpd, node) use `init: true`, so Docker's built-in init forwards signals and reaps zombie processes.

### Design choices

**Virtual Machines vs Docker** — VMs virtualize an entire operating system including the kernel, making them heavier and slower to start. Docker containers share the host kernel and isolate only the user space, making them lighter and faster. VMs offer stronger isolation; containers offer better resource efficiency.

**Secrets vs Environment Variables** — environment variables are visible to any process in the container and can be leaked through logs or inspection. Docker secrets are mounted as files in `/run/secrets/` with restricted permissions, making them significantly harder to expose accidentally. All passwords in this project use secrets; only non-sensitive values use environment variables.

**Docker Network vs Host Network** — host network mode removes isolation and exposes all container ports directly on the host interface, which is a security risk. A Docker bridge network creates an isolated virtual network where containers communicate by service name, and only explicitly declared ports are reachable from outside.

**Docker Volumes vs Bind Mounts** — bind mounts directly expose a host directory path inside the container, creating a tight coupling to the host filesystem structure. Named volumes are managed by Docker (created, listed and removed with `docker volume`) and are referenced by name in the compose file. This project uses two named volumes for the mandatory part (`db_data` and `wp_volume`); the local driver is configured so that their data is stored in `/home/lde-medi/data` on the host, as required by the subject.

## Resources

- Docker documentation: https://docs.docker.com
- NGINX documentation: https://nginx.org/en/docs
- WordPress CLI documentation: https://wp-cli.org
- MariaDB documentation: https://mariadb.com/kb/en
- php-fpm documentation: https://www.php.net/manual/en/install.fpm.php
- Redis documentation: https://redis.io/docs

- vsftpd documentation: https://security.appspot.com/vsftpd/vsftpd_conf.html
- Docker init and PID 1: https://docs.docker.com/reference/compose-file/services/#init

**AI usage** — Claude (Anthropic) was used to:
- help write and proofread this README, `USER_DOC.md` and `DEV_DOC.md`;
- assist in debugging by parsing container logs and identifying configuration errors;
- review the project against the subject before submission, which led to fixes in the Makefile (`clean`/`fclean` no longer delete the secrets or unrelated images), the NGINX healthcheck, WordPress file ownership, FTP write access and signal handling (`init: true`).

All AI-suggested changes were reviewed, tested and are understood by the author.
