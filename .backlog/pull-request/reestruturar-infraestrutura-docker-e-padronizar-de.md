---
name: reestruturar-infraestrutura-docker-e-padronizar-de
pr: 5
title: "PR(#5)-Reestruturar infraestrutura Docker e padronizar Dev Container"
branch: feature/reestruturar-infraestrutura-docker-e-padronizar-de
base: main
extends: feature-05-reestruturar-infraestrutura-docker-e-padronizar-de
status: draft
---

## 📋 Descrição

Implementação de **Reestruturar infraestrutura Docker e padronizar Dev Container** via feature branch `feature/reestruturar-infraestrutura-docker-e-padronizar-de`, com commits atômicos por arquivo.

Feature relacionada: `feature-05-reestruturar-infraestrutura-docker-e-padronizar-de`

---

## 📊 Estatísticas

| Métrica | Valor |
| --- | --- |
| 🌿 Branch de origem | `feature/reestruturar-infraestrutura-docker-e-padronizar-de` |
| 🎯 Branch de destino | `main` |
| 📝 Total de commits de conteúdo | 34 |
| 📁 Arquivos alterados | 32 |
| ➕ Linhas adicionadas | 2178 |
| ➖ Linhas removidas | 721 |

## 📦 Repositórios/branches atualizados

- **`.docker-infra`** — branch `main`
  - Commits: 2
  - Arquivos alterados: 2 — ajuste de detecção de ambiente e regras de arquivos locais
  - Commit publicado: `22eef78`
- **repositório pai** — branch `feature/reestruturar-infraestrutura-docker-e-padronizar-de`
  - Commits: 34 (excluindo o commit inicial vazio)
  - Arquivos alterados: 32 — Dev Container, Docker, VS Code, documentação da feature e da PR, `.gitmodules`, `.gitignore` e gitlink do `.docker-infra`
- **`.ai`** — não atualizado; mantido no commit de referência `db6c9fd`

## Checklist

- [x] Commits separados por arquivo
- [x] Referência da PR incluída nos commits de conteúdo
- [x] Alterações revisadas e enviadas para a branch
- [ ] Revisão funcional
- [ ] Validação em ambiente Linux/jail

## 📝 Commits

- feat(submodule): adicionar infraestrutura Docker modular `.docker-infra` - [fcccae1](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/fcccae1dc7918678946bb990f091990770339113)
- feat(raiz): registrar infraestrutura Docker modular `.gitmodules` - [b4428cf](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/b4428cfcf259efce03666f4ff459aa7b402d45f8)
- feat(init-tasks): adicionar inicialização das tarefas Docker `.vscode/init-tasks` - [bd87a40](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/bd87a40e3626a2aa13ce9a097392aa5b049c6a65)
- feat(raiz): adicionar regras de arquivos locais `.gitignore` - [d2c182b](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/d2c182bfee7a8c4ab29f7c1e98e2560794f8bea8)
- feat(init-docker-servers): adicionar inicialização dos servidores `.docker/init-docker-servers` - [5c86700](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/5c86700bf7db51c9be2d78c9fb4533c9ea1fde09)
- feat(Makefile): adicionar comandos da infraestrutura Docker `.docker/Makefile` - [940c4be](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/940c4be1c7b70017a6311c2a935d76e18250ccb0)
- chore(LICENSE): remover licença legada `LICENSE` - [b3da3d3](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/b3da3d326c1e073925d3cc6b28b624cd5aa1ac4e)
- chore(update-submodules): remover tarefa de submódulos `.vscode/update-submodules` - [ad006e7](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/ad006e7dfb111bef0434e7332c52b0e9147d64d2)
- fix(tasks.json): atualizar tarefas de inicialização `.vscode/tasks.json` - [28493df](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/28493dfef802a29870e4329821c254f96cdaa3a7)
- chore(settings.json): remover configurações legadas `.vscode/settings.json` - [5cb4533](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/5cb453332a4cedec85f6580d8dc23beb5e25e9d0)
- chore(init-docker): remover tarefa legada `.vscode/init-docker` - [9447602](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/944760231f1aabde8fa9ccf5c8167eb65c0eb454)
- chore(docker-compose.yml): remover composição de infraestrutura `.docker/infra/docker-compose.yml` - [d9c49f3](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/d9c49f389b1812c8307e760f8857dd0c100b6707)
- chore(docker-compose.volume.yml): remover volume legado `.docker/infra/docker-compose.volume.yml` - [55e6449](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/55e6449dbcff48f69651a39ac52d17dfeb95c306)
- chore(docker-compose.network.yml): remover rede legada `.docker/infra/docker-compose.network.yml` - [6f6815b](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/6f6815b6cb6eaf00608ec9b71d9770188575020f)
- fix(docker-compose.yml): ajustar execução do DataNode `.docker/infra/datanode/docker-compose.yml` - [8d4a788](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/8d4a788a09ee0e643e3b9b94a5f417f25e3930cd)
- chore(Makefile): remover automação legada `.docker/infra/Makefile` - [825bf1b](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/825bf1b863f7b0a271d5f59dc30634724a606b1a)
- chore(docker-compose.yml): remover composição legada `.docker/docker-compose.yml` - [772f298](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/772f29814d16ee89c5e419884fa5c0caf0384535)
- fix(docker-compose.yml): atualizar serviço base `.docker/base/docker-compose.yml` - [711a4c5](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/711a4c5551645a3faa29783f027426d005d2adbd)
- fix(Dockerfile): atualizar imagem base `.docker/base/Dockerfile` - [8ff584b](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/8ff584b373b3d76a2a52ec6fa4d5ee9dee8f05cb)
- chore(Dockerfile): remover Dockerfile legado `.docker/Dockerfile` - [e02d525](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/e02d525509a1159190515d9fee2a839e7c05841a)
- feat(xauthority.sh): adicionar suporte X11 `.devcontainer/xauthority.sh` - [6df6693](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/6df6693c6865a05f8592943a9ce2f9e18ebac324)
- feat(post-start.sh): adicionar inicialização pós-criação `.devcontainer/post-start.sh` - [202cd89](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/202cd89e2c38c580d1819c6bc4d1be79c3a8fe61)
- feat(docker-entrypoint.sh): adicionar entrypoint `.devcontainer/docker-entrypoint.sh` - [bc2a6c2](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/bc2a6c2f293fe785e1a727318c623a8e3abd3ca8)
- fix(setup-codex.sh): atualizar bootstrap `.devcontainer/setup-codex.sh` - [45d1f2e](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/45d1f2e9def97827aef72c3abea31a84f7684614)
- fix(rstudiobck.sh): atualizar script RStudio `.devcontainer/rstudiobck.sh` - [874642d](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/874642df97d4e1a43a709d78209117dbee37e9fe)
- fix(requirements.txt): atualizar dependências `.devcontainer/requirements.txt` - [e1f15ff](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/e1f15ff6e376c78b0e60a76effef8c9083bfcdcd)
- chore(init-docker): remover inicialização legada `.devcontainer/init-docker` - [739b60f](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/739b60f8ae6d51b85a96c12cf2e945e3fa4c96a1)
- chore(entrypoint.sh): remover entrypoint legado `.devcontainer/entrypoint.sh` - [b11285b](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/b11285b1fe91d696815891cfefe748eb816d860b)
- fix(docker-compose.yml): atualizar serviço do Dev Container `.devcontainer/docker-compose.yml` - [2c53b9b](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/2c53b9b09432d9a378d6e797f2032a2a792314ed)
- fix(devcontainer.json): atualizar configuração `.devcontainer/devcontainer.json` - [9a2087b](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/9a2087b7ffd1e024f9dd98e637a6bc167c9eadc9)
- fix(Dockerfile): atualizar imagem do Dev Container `.devcontainer/Dockerfile` - [6127121](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/612712175aefff4af9e5d4f70aeebc542dbb9203)
- feat(feature-05): adicionar documentação da feature `.backlog/features/feature-05-reestruturar-infraestrutura-docker-e-padronizar-de.md` - [84d8e71](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/84d8e71f943265e1eabbcd75fd2321947d1be133)
- docs(backlog): documentar PR da infraestrutura `.backlog/pull-request/reestruturar-infraestrutura-docker-e-padronizar-de.md` - [dd6f625](https://github.com/HONEY-TI/prj-estacio-rstudio-jupyter/commit/dd6f625)
