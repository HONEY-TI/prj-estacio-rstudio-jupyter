# =========================================================================
# Docker Compose Test - Makefile
# =========================================================================
SHELL := /bin/bash

COMPOSE              := docker compose
RSTUDIO_COMPOSE      := ../.devcontainer/docker-compose.yml
DATANODE_COMPOSE     := infra/datanode/docker-compose.yml
NAMENODE_COMPOSE     := infra/namenode/docker-compose.yml
SPARKMASTER_COMPOSE  := infra/spark-master/docker-compose.yml
SPARKWORKER_COMPOSE  := infra/spark-worker/docker-compose.yml
NODE_VOLUMES         := datanode-data namenode-data

.PHONY: up up-clean prune-clean down prune-rstudio

# Container existe (rodando ou parado)  -> restart
# Não existe                            -> compose up -d --build
# Se o up falhar mas o container passou a existir (criado por outro
# processo durante o build)             -> restart
# uso: $(call start_service,container,compose-file,Rótulo)
define start_service
	@exists() { docker ps -a --format '{{.Names}}' | grep -qx '$(1)'; }; \
	if exists; then \
		status=$$(docker inspect -f '{{.State.Health.Status}}' $(1) 2>/dev/null || true); \
		if [ "$$status" = "healthy" ]; then \
			echo "✅ $(3) já está saudável, nada a fazer."; \
		else \
			echo "⚠️  $(3) está $$status, parando..."; \
			docker stop $(1) >/dev/null || true; \
			echo "🔄 $(3) reiniciando..."; \
			docker restart $(1) >/dev/null || true; \
			status=$$(docker inspect -f '{{.State.Health.Status}}' $(1) 2>/dev/null || true); \
			if [ "$$status" = "unhealthy" ]; then \
				echo "❌ $(3) ficou unhealthy após restart, recriando..."; \
				$(COMPOSE) -f $(2) up -d --build || exit 1; \
			fi; \
		fi; \
	else \
		echo "🚀 $(3) não existe, criando..."; \
		if ! $(COMPOSE) -f $(2) up -d --build; then \
			if exists; then \
				echo "🔄 $(3) foi criado por outro processo, reiniciando..."; \
				docker restart $(1) >/dev/null || exit 1; \
			else \
				exit 1; \
			fi; \
		fi; \
	fi
endef

# Para qualquer container (exceto o dono) que esteja publicando a porta.
# uso: $(call free_port,porta,container-dono)
define free_port
	@for c in $$(docker ps --filter "publish=$(1)" --format '{{.Names}}'); do \
		if [ "$$c" != "$(2)" ]; then \
			echo "⚠️ Porta $(1) em uso por '$$c', parando..."; \
			docker stop "$$c" >/dev/null || true; \
		fi; \
	done
endef

# Espera um container ficar healthy (timeout de 5 min)
# uso: $(call wait_healthy,container,Rótulo)
define wait_healthy
	@echo "Aguardando $(2) ficar saudável..."
	@for i in $$(seq 1 5); do \
		status=$$(docker inspect -f '{{.State.Health.Status}}' $(1) 2>/dev/null); \
		[ "$$status" = "healthy" ] && echo "✅ $(2) saudável." && exit 0; \
		sleep 2; \
	done; \
	echo "Timeout esperando $(2)."; exit 1
endef

define start_rstudio
	$(call free_port,8787,rstudio-devcontainer)
    $(call free_port,8888,rstudio-devcontainer)
	$(call start_service, rstudio-devcontainer,$(RSTUDIO_COMPOSE))

	echo "🚀 Aguardando RS Studio inicializar..."; \
	for i in $$(seq 1 10); do \
		status=$$(docker inspect -f '{{.State.Health.Status}}' rstudio-dev-base 2>/dev/null || true); \
		echo "RS Studio: $$status"; \
		if [ "$$status" = "healthy" ]; then \
			echo "✅ RS Studio saudável."; \
			exit 0; \
		fi; \
		if [ "$$status" = "unhealthy" ]; then \
			echo "❌ RS Studio ficou unhealthy."; \
			break; \
		fi; \
		sleep 2; \
	done; \

	echo "❌ RS Studio não ficou saudável."; \
	echo "⚠️  Parando somente RS Studio..."; \
	docker stop rstudio-dev-base >/dev/null 2>&1 || true; \
	echo "🔽 Derrubando somente RSTUDIO_COMPOSE..."; \
	$(COMPOSE) -f $(RSTUDIO_COMPOSE) down; \
	$(MAKE) prune-clean
endef

up:	
	$(call start_rstudio)

	$(call start_service,namenode,$(NAMENODE_COMPOSE),NameNode)
	$(call wait_healthy,namenode,NameNode)

	$(call start_service,datanode,$(DATANODE_COMPOSE),DataNode)
	$(call wait_healthy,datanode,DataNode)

	$(call start_service,spark-master,$(SPARKMASTER_COMPOSE),Spark Master)
	$(call wait_healthy,spark-master,Spark Master)

	$(call start_service,spark-worker,$(SPARKWORKER_COMPOSE),Spark Worker)
	$(call wait_healthy,spark-worker,Spark Worker)
	
#$(call start_service,rstudio-dev-base,$(RSTUDIO_COMPOSE),RS Studio)
	@echo "🟢 Infraestrutura compartilhada pronta."
#	-exit 0

# Só roda se você chamar explicitamente. Nunca é chamado pelo `up`.
down:
	-$(COMPOSE) -f $(SPARKWORKER_COMPOSE) down
	-$(COMPOSE) -f $(SPARKMASTER_COMPOSE) down
	-$(COMPOSE) -f $(DATANODE_COMPOSE) down
	-$(COMPOSE) -f $(NAMENODE_COMPOSE) down

# Limpeza segura: remove somente recursos não utilizados.
# Não depende do `up`, assim roda mesmo se a infraestrutura falhar.
prune-clean:
	@echo "🧹 Realizando limpeza..."
	-docker builder prune -f
	-docker system prune -f
	-yes | docker volume prune
	@echo "✅ Limpeza concluída."

# Limpeza destrutiva: só roda se chamada explicitamente
prune-rstudio: down
	@echo "🗑️  Parando e removendo containers..."
	@echo "🗑️  Removendo volumes do projeto..."
	-docker volume rm $(NODE_VOLUMES)
	@echo "✅ Limpeza concluída."