# Developer Documentation

## Prerequisites

- VirtualBox with a Debian VM (headless)
- Docker and Docker Compose installed inside the VM
- Make installed inside the VM
- Port 443 and 21 forwarded from host to VM via VirtualBox NAT

To set up port forwarding from the host machine:

```bash
VBoxManage modifyvm "vm_name" --natpf1 "https,tcp,,443,,443"
VBoxManage modifyvm "vm_name" --natpf1 "ftp,tcp,,21,,21"
```

Add the following entries to `/etc/hosts` on both the host machine and inside the VM:

```
127.0.0.1 lde-medi.42.fr
127.0.0.1 bonus.lde-medi.42.fr
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
            └── portainer/
```

---

## Credentials architecture

This project separates non-sensitive configuration from sensitive credentials.

### `srcs/.env`

Contains only non-sensitive values — no passwords. Tracked by `.gitignore`, never committed.

```
DOMAIN_NAME=lde-medi.42.fr
MYSQL_USER=lde-medi
MYSQL_DB=inception_db
WP_ADMIN_USER=me
WP_ADMIN_EMAIL=me@mail.com
WP_USER=example
WP_USER_EMAIL=ex@mp.le
FTP_USER=meftp
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
DB_PASSWORD=$(cat /run/secrets/db_password)
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

Create the data directories before the first run:

```bash
mkdir -p ~/data/mysql
mkdir -p ~/data/wordpress
mkdir -p ~/data/portainer
```

From the repository root:

```bash
make
```

Or directly from `srcs/`:

```bash
docker compose up --build
```

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
| db_data | ~/data/mysql | /var/lib/mysql | mariadb |
| wp_volume | ~/data/wordpress | /var/www/html | wordpress, nginx, ftp |
| portainer_data | ~/data/portainer | /data | portainer |

Data in these directories survives `docker compose down`. To completely reset the project state:

```bash
docker compose down
rm -rf ~/data/mysql/*
rm -rf ~/data/wordpress/*
rm -rf ~/data/portainer/*
docker compose up --build
```

---

## Initialization logic

Each container runs an `init.sh` script as its entrypoint. The script reads passwords from `/run/secrets/` and checks for a sentinel before running setup commands, preventing data loss on restart.

| Container | Sentinel |
|---|---|
| mariadb | `/var/lib/mysql/mysql` |
| wordpress | `/var/www/html/wp-config.php` |

If the sentinel exists, the setup phase is skipped and the service starts directly.

---

## Network

All containers communicate over a single internal bridge network named `inception_net`. NGINX is the sole entrypoint for HTTPS traffic. FTP exposes its own ports directly.

| Container | Internal port | External port |
|---|---|---|
| nginx | 443 | 443 |
| ftp | 21, 21000-21010 | 21, 21000-21010 |
| wordpress | 9000 | — |
| mariadb | 3306 | — |
| redis | 6379 | — |
| adminer | 8080 | — |
| static | 80 | — |
| portainer | 9000 | — |
