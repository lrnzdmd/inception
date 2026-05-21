COMPOSE_FILE	= srcs/docker-compose.yml
DATA_DIR		= $(HOME)/data
DIRS			= $(DATA_DIR)/mysql $(DATA_DIR)/wordpress $(DATA_DIR)/portainer

all: setup up

setup:
	@echo "Creating data directories..."
	@mkdir -p $(DIRS)

up: setup
	sudo docker compose -f $(COMPOSE_FILE) up --build -d

down:
	sudo docker compose -f $(COMPOSE_FILE) down

stop:
	sudo docker compose -f $(COMPOSE_FILE) stop

start:
	sudo docker compose -f $(COMPOSE_FILE) start

logs:
	sudo docker compose -f $(COMPOSE_FILE) logs -f

status:
	sudo docker compose -f $(COMPOSE_FILE) ps

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
	@echo "Removing volumes..."
	sudo docker compose -f $(COMPOSE_FILE) down -v
	@echo "Removing images..."
	sudo docker rmi $$(sudo docker images -q) 2>/dev/null || true

fclean: clean
	@echo "Removing data directories..."
	sudo rm -rf $(DIRS)
	@echo "Pruning docker system..."
	sudo docker system prune -af

re: fclean all

.PHONY: all setup up down stop start logs status help clean fclean re
