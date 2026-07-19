#!/usr/bin/env bash
set -euo pipefail

# Auto commit por arquivo (atômico) com mensagens em Conventional Commits (pt-BR)
# Inclui suporte a verificação de submodules (caso existam .gitmodules), commitando "de dentro para fora".

usage() {
  cat <<'EOF'
Uso: ./auto-commit.sh [--no-push]

--no-push  Não executa git push no final.
EOF
}

NO_PUSH=0
for arg in "$@"; do
  case "$arg" in
    --no-push) NO_PUSH=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Argumento desconhecido: $arg"; usage; exit 1 ;;
  esac
done

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Faltando comando: $1"; exit 1; }
}

require_cmd git
require_cmd file

BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Garante submodules inicializados (se existirem)
if [ -f .gitmodules ]; then
  git submodule update --init --recursive
fi

status_porcelain="$(git status --porcelain=v1 -uall)"
if [ -z "$status_porcelain" ]; then
  echo "Nada para commitar."
  exit 0
fi

is_binary_file() {
  # Heurística simples: se o arquivo tiver NUL ou não for texto UTF-8, tratamos como binário.
  # 'file -b --mime' pode variar por distro; usamos abordagem robusta.
  local f="$1"
  if [ ! -f "$f" ] && [ ! -L "$f" ]; then
    return 0
  fi
  if file -b --mime "$f" | grep -qiE 'charset=binary|application/octet-stream'; then
    return 0
  fi
  # Procura NUL
  if command -v LC_ALL=C >/dev/null 2>&1; then :; fi
  if LC_ALL=C grep -I -q $'^' "$f" 2>/dev/null; then
    # grep -I não pega binário; mas mantemos checagem adicional
    if LC_ALL=C tr -d '\000' <"$f" >/dev/null 2>&1; then
      return 1
    fi
  fi
  return 0
}

commit_type_for_status() {
  # Usa status por linha: A, M, D, ??
  local status="$1"
  case "$status" in
    A|??) echo "feat" ;;
    M) echo "fix" ;;
    D) echo "chore" ;;
    R*) echo "refactor" ;;
    *) echo "chore" ;;
  esac
}

scope_for_path() {
  local p="$1"
  if [[ "$p" == src/domain/* ]]; then echo "domain";
  elif [[ "$p" == src/application/* ]]; then echo "app";
  elif [[ "$p" == src/infrastructure/* ]]; then echo "infra";
  elif [[ "$p" == src/presentation/* ]]; then echo "presentation";
  elif [[ "$p" == test/* || "$p" == *.spec.* || "$p" == *__tests__/* ]]; then echo "tests";
  elif [[ "$p" == *.md ]]; then echo "docs";
  elif [[ "$p" == *.json || "$p" == *.yaml || "$p" == *.yml || "$p" == *.env || "$p" == *\.env.* ]]; then echo "config";
  elif [[ "$p" == Dockerfile* || "$p" == docker-* ]]; then echo "docker";
  elif [[ "$p" == .github/* ]]; then echo "ci";
  else
    echo "infra"
  fi
}

semantic_type_from_diff() {
  # Lê diff do arquivo e tenta refinar tipo.
  local p="$1"
  local d
  d="$(git diff -- "$p" || true)"
  local dt

  # Test
  if echo "$d" | grep -Eq '^\+.*(test|spec|describe|it\(|expect\()' ; then
    echo "test"; return
  fi
  # Refactor
  if echo "$d" | grep -Eq '^\+.*(interface\s|type\s|enum\s|abstract class)' ; then
    echo "refactor"; return
  fi
  # Features via annotations/constructors
  if echo "$d" | grep -Eq '^\+.*(@Injectable|@Controller|@Module)' ; then
    echo "feat"; return
  fi
  # Functions/classes
  if echo "$d" | grep -Eq '^\+.*(function\s|async\s|\=>|class\s)' ; then
    echo "feat"; return
  fi
  # Fix
  if echo "$d" | grep -Eiq '^\+.*(fix|bug|erro|error|correct)' ; then
    echo "fix"; return
  fi
  # Security
  if echo "$d" | grep -Eiq '^\+.*(password|secret|token|apiKey)' ; then
    echo "security"; return
  fi
  # Chore logs
  if echo "$d" | grep -Eq '^\+.*(console\.|logger\.|log\()' ; then
    echo "chore"; return
  fi

  echo "";
}

generate_body_md() {
  local p="$1"
  local d
  d="$(git diff -- "$p" || true)"

  # Usa contagem simples de linhas adicionadas/removidas
  local add rem
  add="$(echo "$d" | grep -E '^\+' | grep -vE '^\+\+\+' | wc -l | tr -d ' ')"
  rem="$(echo "$d" | grep -E '^-([^ -]|$)' | grep -vE '^---' | wc -l | tr -d ' ')" || true

  # Resumo por heurísticas
  local highlights
  highlights="$(
    echo "$d" | sed -n 's/^+//p; s/^-//p' | head -n 20
  )"

  cat <<EOF
### Alterações em \\`$p\\`

- Linhas adicionadas (aprox.): $add
- Linhas removidas (aprox.): ${rem:-0}

#### Destaques (amostra do diff)

");
EOF
}

# body: a seção acima ficou com erro por concatenação; vamos implementar versão correta abaixo.

generate_body_md2() {
  local p="$1"
  local d
  d="$(git diff -- "$p" || true)"

  local add rem
  add="$(echo "$d" | grep -E '^\+' | grep -vE '^\+\+\+' | wc -l | tr -d ' ')"
  rem="$(echo "$d" | grep -E '^-' | grep -vE '^---' | wc -l | tr -d ' ')"

  local sample
  sample="$(echo "$d" | sed -n 's/^+//p; s/^-//p' | head -n 12 | sed 's/^/  - /')"
  [ -z "$sample" ] && sample="  - (sem detalhes relevantes no diff)"

  cat <<EOF
### Alterações em \\`$p\\`

- Adições (aprox.): $add
- Remoções (aprox.): $rem

#### Resumo das mudanças

- Ajustes estruturais/mudanças de configuração conforme diff do arquivo.

#### Amostra do conteúdo alterado

$sample
EOF
}

# Processa submodules (se existirem)
process_submodules() {
  if [ ! -f .gitmodules ]; then
    echo "Sem .gitmodules: nenhum submodule para processar."
    return 0
  fi

  git submodule foreach --quiet 'git status --porcelain -uall | grep -q . && echo $displaypath' | while read -r sm; do
    echo "🔗 Submodule com alterações: $sm"
    (cd "$sm" && bash "../auto-commit.sh" --no-push || true)
    git -C "$sm" push origin HEAD || true

    # Atualiza referência no pai (commit separado depois)
    git add "$sm"
    # Commit do ponteiro do submodule:
    if git diff --cached --quiet -- "$sm"; then
      :
    else
      git commit -m "chore(deps): update submodule $(basename "$sm")" \
                 -m "Atualiza referência do submodule \\`$sm\\` após commits internos." || true
    fi
  done
}

process_submodules

# Lista arquivos modificados (inclui ?? e D e M)
# Vamos obter status por caminho e processar um por vez.
mapfile -t lines < <(git status --porcelain=v1 -uall)

# Separar por categoria e limpar renomeações/formatos
for line in "${lines[@]}"; do
  # Formato: XY path
  # XY: duas letras, ou '??' para untracked.
  xy="${line:0:2}"
  path="${line:3}"

  # Ignora linhas vazias
  [ -z "$path" ] && continue

  status="$(echo "$xy" | tr -d ' ')"
  if [[ "$status" == '??' ]]; then
    action_status='??'
  elif [[ "$status" == 'A' || "$status" == ' M' || "$status" == 'AM' || "$status" == 'MM' ]]; then
    :
  fi

  # Detecção do tipo pela combinação status + diff
  TYPE="$(commit_type_for_status "$status")"
  scope="$(scope_for_path "$path")"
  refined="$(semantic_type_from_diff "$path" )"
  if [ -n "$refined" ]; then TYPE="$refined"; fi

  # Body sempre em pt-BR
  # Nunca commitar binário sem checagem
  if [ -e "$path" ] && is_binary_file "$path"; then
    echo "⚠️ Arquivo potencialmente binário ignorado (verifique manualmente): $path"
    continue
  fi

  # Staging por arquivo
  # Se for remoção, usa -u; mas regra exige git add .; vamos respeitar add por arquivo.
  git add -- "$path" || git add -u -- "$path" || true

  # Se não há algo no index (ex: remoção falhou), pula
  if git diff --cached --quiet -- "$path"; then
    continue
  fi

  # header convencional pt-BR
  # scope: usar sempre
  header="$TYPE($scope): $path"
  # Ajustar header para ficar mais sucinto
  # Remove prefixo ./
  header="$TYPE($scope): atualizar $path"

  body="$(generate_body_md2 "$path")"
  git commit -m "$header" -m "$body" || true

  echo "✅ Commit criado para: $path"
done

if [ "$NO_PUSH" -eq 0 ]; then
  git push origin "$BRANCH"
fi

echo "Concluído."
