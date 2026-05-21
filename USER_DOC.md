# User Documentation

## Services

| Service | Description | Access |
|---|---|---|
| WordPress | Main website with CMS | https://lde-medi.42.fr |
| Static site | Static HTML/CSS website | https://bonus.lde-medi.42.fr |
| Adminer | Database management interface | internal only |
| Portainer | Container management interface | internal only |
| FTP | File access to WordPress volume | lde-medi.42.fr port 21 |
| Redis | Object cache for WordPress | internal only |
| MariaDB | Database | internal only |

---

## Starting and stopping the project

From the repository root:

```bash
# Start all services
make

# Stop all services without removing data
make down

# Stop all services and remove all data
make fclean
```

---

## Accessing the website

Open a browser and navigate to `https://lde-medi.42.fr`.

The site uses a self-signed TLS certificate. The browser will display a security warning — click "Advanced" and proceed to the site. This is expected behavior.

To access the WordPress administration panel, navigate to `https://lde-medi.42.fr/wp-admin` and log in with the administrator credentials.

---

## Credentials

No passwords are stored in environment variables or configuration files. All passwords are stored in individual files inside the `secrets/` directory at the root of the repository. This directory is not tracked by Git.

| Secret | File |
|---|---|
| MariaDB user password | `secrets/db_password.txt` |
| MariaDB root password | `secrets/db_root_password.txt` |
| MariaDB admin password | `secrets/db_admin_password.txt` |
| WordPress admin password | `secrets/wp_admin_password.txt` |
| WordPress user password | `secrets/wp_user_password.txt` |
| FTP password | `secrets/ftp_password.txt` |

Non-sensitive configuration (domain name, usernames, emails) is stored in `srcs/.env`.

---

## Checking that services are running correctly

```bash
# Show status of all containers
docker ps
```

All containers should show `Up` in the STATUS column. If any container shows `Restarting` or `Exited`, check its logs:

```bash
docker logs <container_name>
```

To verify that WordPress can reach the database:

```bash
docker exec -it wordpress mysqladmin ping -h mariadb -u $MYSQL_USER -p$(cat /run/secrets/db_password)
```

The expected response is `mysqld is alive`.
