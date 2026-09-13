# =========================================================================
# Docker Compospe Test - Makefile
# =========================================================================
SHELL := /bin/bash

COMPOSE       := docker compose
CONTAINER_INFRA := docker-compose.yml
DATANODE_COMPOSE := datanode/docker-compose.yml
NAMENODE_COMPOSE := namenode/docker-compose.yml
SPARKMASTER_COMPOSE := spark-master/docker-compose.yml
SPARKWORKER_COMPOSE := spark-worker/docker-compose.yml

ROOT_COMPOSE  := ../docker-compose.yml

DEV_CONTAINER_NAME  := rstudio-dev-base
NODE_VOLUMES  :=  datanode-data namenode-data

PHONY: infra-up infra-down clean-devcontainer rebuild-devcontainer

# ============================================================
# Infraestrutura completa
# ============================================================
infra: ## Cria network + volumes (profile init), sem iniciar containers de app
	$(COMPOSE) -f $(CONTAINER_INFRA) --profile init up --no-start
	@echo "✔ Rede e volumes prontos."

up: infra datanode namenode spark-master spark-worker down
	-$(COMPOSE) -f namenode/docker-compose.yml up -d --build 
	@echo "Aguardando NameNode ficar saudável..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' namenode 2>/dev/null)" = "healthy" ]; do \
		sleep 2; \
	done
	@echo "NameNode saudável."

	-$(COMPOSE) -f datanode/docker-compose.yml up -d --build 
	@echo "Aguardando DataNode ficar saudável..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' datanode 2>/dev/null)" = "healthy" ]; do \
		sleep 2; \
	done
	@echo "DataNode saudável."

	-$(COMPOSE) -f spark-master/docker-compose.yml up -d --build 
	@echo "Aguardando Spark Master ficar saudável..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' spark-master 2>/dev/null)" = "healthy" ]; do \
		sleep 2; \
	done
	@echo "Spark Master saudável."

	-$(COMPOSE) -f spark-worker/docker-compose.yml up -d  --build 
	@echo "Aguardando Spark Worker ficar saudável..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' spark-worker 2>/dev/null)" = "healthy" ]; do \
		sleep 2; \
	done
	@echo "Spark Worker saudável."

	-$(COMPOSE) -f $(ROOT_COMPOSE) build

	@echo ""
	@echo "Infraestrutura compartilhada pronta."


down: prune-volumes
	-$(COMPOSE) -f spark-worker/docker-compose.yml down
	-$(COMPOSE) -f spark-master/docker-compose.yml down
	-$(COMPOSE) -f datanode/docker-compose.yml down
	-$(COMPOSE) -f namenode/docker-compose.yml down

prune-volumes:
	@echo "Parando e removendo containers..."
	-docker rm --force rs-network-init
	-docker rm --force rs-dev-volumes-init
	-docker rm --force rs-infra
	-$(COMPOSE) -f $(ROOT_COMPOSE) down
	-docker rm --force $(DEV_CONTAINER_NAME) 2>/dev/null
	-docker ps -aq --filter "name=persona" | xargs -r docker rm --force
	@echo "Removendo volumes..."
	-yes | docker volume prune
	@echo "Limpeza concluída."