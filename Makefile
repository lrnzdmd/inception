COMPOSE_FILE    = srcs/docker-compose.yml
DATA_DIR        = $(HOME)/data
DIRS            = $(DATA_DIR)/mysql $(DATA_DIR)/wordpress $(DATA_DIR)/uptime-kuma secrets

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
	@echo "  clean     Remove containers, volumes and images"
	@echo "  fclean    clean + delete data directories + docker system prune"
	@echo "  re        fclean + all (full rebuild from scratch)"
	@echo "  help      Show this help message"

clean: down
	@echo "Removing containers, networks and volumes..."
	docker compose -f $(COMPOSE_FILE) down -v
	@echo "Removing images..."
	docker rmi $$(docker images -q) 2>/dev/null || true

fclean: clean
	@echo "Removing data directories via Docker helper..."
	docker run --rm -v $(DATA_DIR):/data alpine rm -rf /data/mysql /data/wordpress /data/portainer
	rm -rf secrets $(DATA_DIR)
	@echo "Pruning docker system..."
	docker system prune -af

re: fclean all

.PHONY: all setup up down stop start logs status help clean fclean re