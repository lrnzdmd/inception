# Developer Documentation

## Prerequisites

- VirtualBox with a VM
- Docker and Docker Compose installed inside the VM
- Make installed inside the VM

Add the following entries to `/etc/hosts` inside the VM:

```
127.0.0.1 lde-medi.42.fr
127.0.0.1 bonus.lde-medi.42.fr
127.0.0.1 adminer.lde-medi.42.fr
127.0.0.1 kuma.lde-medi.42.fr
```

---

## Repository structure

```
inception/
├── Makefile
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── db_admin_password.txt
│   ├── wp_user_password.txt
│   ├── wp_admin_password.txt
│   └── ftp_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/my.cnf
        │   └── tools/init.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/init.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/init.sh
        └── bonus/
            ├── adminer/
            ├── ftp/
            ├── redis/
            ├── static/
            └── uptime-kuma/
```

---

## Credentials architecture

This project separates non-sensitive configuration from sensitive credentials.

### `srcs/.env`

Contains only non-sensitive values — no passwords. Ignored via `.gitignore`, never committed.

```
DOMAIN_NAME=lde-medi.42.fr
MYSQL_ADMIN_USER=dbking
MYSQL_USER=lde-medi
MYSQL_DB=inception_db
WP_ADMIN_USER=me
WP_ADMIN_EMAIL=me@mail.com
WP_USER=example
WP_USER_EMAIL=ex@mp.le
FTP_USER=meftp
# Optional: address announced in FTP passive mode (default 127.0.0.1).
# Set it to the VM IP to use FTP from outside the VM.
FTP_PASV_ADDRESS=127.0.0.1
```

### `secrets/`

Contains one password per file. Each file is mounted read-only inside the relevant container at `/run/secrets/<name>`. Never committed to Git.

| File | Used by | Mounted as |
|---|---|---|
| `db_password.txt` | mariadb, wordpress | `/run/secrets/db_password` |
| `db_root_password.txt` | mariadb | `/run/secrets/db_root_password` |
| `db_admin_password.txt` | mariadb | `/run/secrets/db_admin_password` |
| `wp_admin_password.txt` | wordpress | `/run/secrets/wp_admin_password` |
| `wp_user_password.txt` | wordpress | `/run/secrets/wp_user_password` |
| `ftp_password.txt` | ftp | `/run/secrets/ftp_password` |

Inside each `init.sh`, passwords are read from the mounted secret file rather than from environment variables:

```sh
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
```

### Creating the secret files

Before the first run, create all secret files manually:

```bash
mkdir -p secrets
echo "your_password_here" > secrets/db_password.txt
echo "your_password_here" > secrets/db_root_password.txt
echo "your_password_here" > secrets/db_admin_password.txt
echo "your_password_here" > secrets/wp_admin_password.txt
echo "your_password_here" > secrets/wp_user_password.txt
echo "your_password_here" > secrets/ftp_password.txt
```

---

## Building and launching the project

From the repository root:

```bash
make
```

Or directly from `srcs/`:

```bash
docker compose up --build
```

### Makefile targets

| Target | Effect |
|---|---|
| `make` / `make all` | Create `/home/lde-medi/data/*` directories, build images and start the stack |
| `make setup` | Create the data directories only |
| `make up` | Build and start all containers in background |
| `make down` | Stop and remove containers (data preserved) |
| `make stop` / `make start` | Stop / restart containers without removing them |
| `make logs` | Follow logs of all containers |
| `make status` | Show containers status (`docker compose ps`) |
| `make clean` | Remove containers, volumes, network and project images (data on disk preserved) |
| `make fclean` | `clean` + delete `/home/lde-medi/data` + Docker build cache (secrets are kept) |
| `make re` | `fclean` + `all` |
| `make help` | List the targets |

---

## Services

Each service runs in its own container, built from its own Dockerfile on `debian:bookworm`. The quick checks below assume you are at the repository root; to reuse the values from `srcs/.env` in your shell, load it first:

```bash
set -a; . srcs/.env; set +a
docker compose -f srcs/docker-compose.yml ps   # every container Up, mariadb/wordpress/nginx (healthy)
```

### NGINX

Single entrypoint of the stack, listening on 443 only with TLSv1.2/TLSv1.3. A self-signed certificate is generated at startup (`nginx/tools/init.sh`), then requests are routed by `server_name`: PHP to `wordpress:9000` (FastCGI), static files from the shared WordPress volume, bonus subdomains to their containers.

To check that only HTTPS is served and which TLS versions are accepted:

```bash
curl -I http://${DOMAIN_NAME}                                     # connection refused (port 80 not published)
curl -kI https://${DOMAIN_NAME}                                   # HTTP/1.1 200
openssl s_client -connect ${DOMAIN_NAME}:443 -tls1_2 </dev/null 2>/dev/null | grep Protocol
openssl s_client -connect ${DOMAIN_NAME}:443 -tls1_3 </dev/null 2>/dev/null | grep Protocol
openssl s_client -connect ${DOMAIN_NAME}:443 -tls1_1 </dev/null   # handshake failure
```

### WordPress + php-fpm

php-fpm 8.2 listening on port 9000, no web server in the container. On first start `wordpress/tools/init.sh` downloads WordPress with WP-CLI, writes `wp-config.php`, installs the site, creates the second user (`WP_USER`, role author) and enables the Redis object cache. On later starts the installation is skipped because `wp-config.php` already exists.

To check the installation and the users:

```bash
docker exec wordpress wp core is-installed --allow-root --path=/var/www/html && echo installed
docker exec wordpress wp user list --allow-root --path=/var/www/html --fields=user_login,roles
```

The site is at `https://lde-medi.42.fr`, the dashboard at `https://lde-medi.42.fr/wp-admin`.

### MariaDB

Database server listening on 3306 on the internal network only. `mariadb/tools/init.sh` initializes the data directory on first run, then creates the database, the WordPress user and the admin user, and sets the root password (root can only log in from inside the container).

To log in and check that the database is populated:

```bash
docker exec -it mariadb mariadb -u root -p          # password in secrets/db_root_password.txt
```
```sql
SHOW DATABASES;
USE inception_db;
SHOW TABLES;
SELECT user_login FROM wp_users;
SELECT user, host FROM mysql.user;
```

### Redis (bonus)

In-memory object cache for WordPress (plugin `redis-cache`, limited to 128 MB with LRU eviction), so repeated queries do not hit MariaDB.

To check that WordPress is connected and that keys are being stored:

```bash
docker exec wordpress wp redis status --allow-root --path=/var/www/html   # Status: Connected
docker exec redis redis-cli dbsize                                        # > 0 after browsing the site
docker exec -it redis redis-cli monitor                                   # live commands while reloading a page
```

### FTP (bonus)

vsftpd giving access to the WordPress volume, with the user chrooted in `/var/www/html` and passive mode on ports 21000-21010. The FTP user shares uid 33 with `www-data`, so uploaded files are directly usable by WordPress.

To list the files and upload one:

```bash
curl -u "${FTP_USER}:$(cat secrets/ftp_password.txt)" ftp://127.0.0.1/
echo "hello" > /tmp/test.txt
curl -u "${FTP_USER}:$(cat secrets/ftp_password.txt)" -T /tmp/test.txt ftp://127.0.0.1/wp-content/
docker exec wordpress ls -l /var/www/html/wp-content/test.txt                 # owned by www-data
```

### Static website (bonus)

HTML/CSS site (no PHP) served by `busybox httpd` on port 80 inside the network, reverse-proxied by NGINX on `bonus.lde-medi.42.fr`.

```bash
curl -k https://bonus.${DOMAIN_NAME} | head
```

### Adminer (bonus)

Web interface for the database, running on its own php-fpm (port 9000) and reached through NGINX on `adminer.lde-medi.42.fr`. Log in with server `mariadb` and `MYSQL_ADMIN_USER` or `MYSQL_USER`.

```bash
curl -ks https://adminer.${DOMAIN_NAME} | grep -o '<title>.*</title>'
```

### Uptime Kuma (bonus)

Monitoring dashboard built from source, used to keep an eye on the availability of every service (HTTP and TCP monitors, history, notifications). Its data lives in the dedicated `uptime_data` volume. Open `https://kuma.lde-medi.42.fr`, create the account on first access, then add monitors such as `mariadb:3306`, `redis:6379` (TCP) or `https://nginx` (HTTP, ignore TLS errors).

```bash
curl -kI https://kuma.${DOMAIN_NAME}
```

---

## Changing a service port

After any change, rebuild with `make down && make up`.

| Service | What to change |
|---|---|
| NGINX (published port, e.g. 8443) | `ports:` of `nginx` in `srcs/docker-compose.yml` → `"8443:443"`. WordPress builds its URL from the request Host header, so `https://lde-medi.42.fr:8443` works without touching the database. |
| NGINX (internal port) | `listen` directives in `nginx/conf/nginx.conf`, the `ports:` mapping and the `curl` healthcheck URL in the compose file |
| WordPress / php-fpm (9000) | `listen` in `wordpress/conf/www.conf`, `fastcgi_pass wordpress:<port>` in `nginx/conf/nginx.conf`, `/dev/tcp/127.0.0.1/<port>` healthcheck in the compose file |
| MariaDB (3306) | `port` in `mariadb/conf/my.cnf`; `DB_HOST` in `wp-config.php` (`wp config set DB_HOST mariadb:<port>`, or `make fclean` to reinstall) and `-P <port>` in the `mysqladmin ping` of `wordpress/tools/init.sh` |
| Redis (6379) | `--port <port>` in the redis `CMD` and `WP_REDIS_PORT` in `wordpress/tools/init.sh` / `wp-config.php` |
| FTP (21) | add `listen_port=<port>` to the vsftpd config in `ftp/tools/init.sh` and update the `ports:` mapping |

---

## Managing containers and volumes

```bash
# Show running containers
docker ps

# Show all containers including stopped ones
docker ps -a

# Follow logs of a specific container
docker logs -f <container_name>

# Enter a running container
docker exec -it <container_name> sh

# Stop all containers without removing data
docker compose down

# Stop all containers and remove volumes
docker compose down -v

# Rebuild and restart a single service
docker compose up --build <service_name>
```

---

## Data persistence

All persistent data is stored outside the containers in named volumes backed by directories on the host.

| Volume | Host path | Container path | Service |
|---|---|---|---|
| db_data | /home/lde-medi/data/mysql | /var/lib/mysql | mariadb |
| wp_volume | /home/lde-medi/data/wordpress | /var/www/html | wordpress, nginx, ftp |
| uptime_data | /home/lde-medi/data/uptime-kuma | /app/data | uptime-kuma |

Docker prefixes the volume names with the compose project name (`srcs`). To see where a volume stores its data:

```bash
docker volume ls
docker volume inspect srcs_wp_volume srcs_db_data | grep device
```

Data in these directories survives `docker compose down` and a reboot of the VM. To completely reset the project state:

```bash
docker compose down
sudo rm -rf /home/lde-medi/data/mysql/*
sudo rm -rf /home/lde-medi/data/wordpress/*
sudo rm -rf /home/lde-medi/data/uptime-kuma/*
docker compose up --build
```

---

## Network

All containers communicate over a single internal bridge network named `inception_net`, resolving each other by service name through Docker's internal DNS. NGINX is the sole entrypoint for HTTPS traffic. FTP exposes its own ports directly.

```bash
docker network ls                                   # srcs_inception_net
docker network inspect srcs_inception_net --format '{{range .Containers}}{{.Name}} {{end}}'
```

| Container | Internal port | External port |
|---|---|---|
| nginx | 443 | 443 |
| ftp | 21, 21000-21010 | 21, 21000-21010 |
| wordpress | 9000 | — |
| mariadb | 3306 | — |
| redis | 6379 | — |
| adminer | 9000 | — |
| static | 80 | — |
| uptime-kuma | 3001 | — |
