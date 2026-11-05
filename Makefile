COMPOSE_FILE    = srcs/docker-compose.yml
DATA_DIR        = /home/lde-medi/data
DIRS            = $(DATA_DIR)/mysql $(DATA_DIR)/wordpress $(DATA_DIR)/uptime-kuma

all: setup up

setup:
	@echo "Creating data directories..."
	@mkdir -p $(DIRS)

up: setup
	docker compose -f $(COMPOSE_FILE) up --build -d

down:
	docker compose -f $(COMPOSE_FILE) down

stop:
	docker compose -f $(COMPOSE_FILE) stop

start:
	docker compose -f $(COMPOSE_FILE) start

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

status:
	docker compose -f $(COMPOSE_FILE) ps

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all       Create data directories and launch the stack (default)"
	@echo "  setup     Create data directories only"
	@echo "  up        Build and start all containers in background"
	@echo "  down      Stop and remove containers (volumes preserved)"
	@echo "  stop      Stop containers without removing them"
	@echo "  start     Restart containers stopped with 'stop'"
	@echo "  logs      Follow logs of all containers in real time"
	@echo "  status    Show status of all containers"
	@echo "  clean     Remove containers, volumes and project images"
	@echo "  fclean    clean + delete data directories + build cache"
	@echo "  re        fclean + all (full rebuild from scratch)"
	@echo "  help      Show this help message"

clean:
	@echo "Removing containers, networks, volumes and project images..."
	docker compose -f $(COMPOSE_FILE) down -v --rmi all --remove-orphans

fclean: clean
	@echo "Removing data directories via Docker helper..."
	docker run --rm -v $(DATA_DIR):/data debian:bookworm rm -rf /data/mysql /data/wordpress /data/uptime-kuma
	rm -rf $(DATA_DIR)
	@echo "Removing build cache..."
	docker builder prune -af

re: fclean all

.PHONY: all setup up down stop start logs status help clean fclean re