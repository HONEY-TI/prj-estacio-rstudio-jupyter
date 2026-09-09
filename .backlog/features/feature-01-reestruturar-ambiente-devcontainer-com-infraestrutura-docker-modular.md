---
name: feature-01-reestruturar-ambiente-devcontainer-com-infraestrutura-docker-modular
file: feature-01-reestruturar-ambiente-devcontainer-com-infraestrutura-docker-modular.md
description: >
  Reestruturação do ambiente DevContainer e da infraestrutura Docker em componentes
  modulares para RStudio, Jupyter, Spark e Hadoop.
---

## Contexto / Problema

O ambiente concentrava a imagem de desenvolvimento e os serviços de infraestrutura em arquivos
Docker Compose acoplados, dificultando a manutenção, a inicialização independente dos serviços e
a configuração do DevContainer.

## Objetivo

Separar a construção das imagens, a infraestrutura compartilhada e o DevContainer, adicionando
scripts de inicialização, configuração do ambiente e suporte às ferramentas de desenvolvimento.

## Critérios de aceite

> Rascunho — revisar e complementar manualmente.

- [ ] Validar a construção das imagens Docker base e de desenvolvimento.
- [ ] Validar a inicialização independente da infraestrutura Spark e Hadoop.
- [ ] Validar a abertura do DevContainer com o workspace e as ferramentas configuradas.
