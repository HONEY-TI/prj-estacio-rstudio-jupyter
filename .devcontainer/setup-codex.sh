#!/usr/bin/env bash
#
# Prepara o Codex dentro do container:
#   1. valida o ambiente
#   2. garante autenticação (device auth, com ponte para a extensão VS Code)
#   3. marca o workspace como trusted
#   4. valida os arquivos TOML
#   5. executa o comando recebido (exec "$@")
#
set -Eeuo pipefail

# ==========================================================
# Constantes
# ==========================================================

readonly LOG_PREFIX="[codex]"

# Usuário atual, qualquer um.
CURRENT_USER="$(id -un)"
readonly CURRENT_USER

# HOME vem do /etc/passwd, não do ambiente (que pode estar como /root).
USER_HOME="$(getent passwd "$CURRENT_USER" | cut -d: -f6)"
USER_HOME="${USER_HOME:-$HOME}"
readonly USER_HOME
export HOME="$USER_HOME"

readonly WORKSPACE="${WORKSPACE:-/workspace}"

# 📁 Usa o .codex criado pelo bootstrap (não depende de /home/<user>/.codex).
# Sem ${CODEX_HOME:-...} de propósito: um valor antigo vindo do ambiente não deve vencer.
readonly CODEX_HOME="$WORKSPACE/.codex"
export CODEX_HOME
readonly CODEX_CONFIG="$CODEX_HOME/config.toml"
readonly PROJECT_CONFIG="$CODEX_CONFIG"

# 🌉 Ponte de device-auth na mesma pasta.
readonly BRIDGE_DIR="$CODEX_HOME"
readonly DEVICE_AUTH_FILE="$BRIDGE_DIR/device-auth.json"
readonly AUTH_FILE="$CODEX_HOME/auth.json"

readonly DEVICE_URL="https://auth.openai.com/codex/device"
readonly DEVICE_CODE_TIMEOUT_SECONDS=120

# ==========================================================
# Estado (usado pelo cleanup)
# ==========================================================

LOGIN_OUTPUT=""
LOGIN_PID=""
TAIL_PID=""

# ==========================================================
# Log
# ==========================================================

log()   { echo "$LOG_PREFIX $*"; }
error() { echo "$LOG_PREFIX ERRO: $*" >&2; }

die() {
    local exit_code="$1"
    shift
    error "$*"
    exit "$exit_code"
}

on_error() {
    local exit_code="$1" line="$2" command="$3"
    echo "$LOG_PREFIX ERRO linha $line: $command (exit $exit_code)" >&2
}

# ==========================================================
# Cleanup
# ==========================================================

stop_process() {
    local pid="$1"
    [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
}

cleanup_login() {
    stop_process "$TAIL_PID"
    stop_process "$LOGIN_PID"
    rm -rf "$LOGIN_OUTPUT" "$DEVICE_AUTH_FILE" "$DEVICE_AUTH_FILE.tmp" "AUTH_FILE"
   
     # Limpa o conteúdo de $CODEX_HOME/tmp, mas mantém a pasta.
    if [[ -d "$CODEX_HOME/tmp" ]]; then
        find "$CODEX_HOME/tmp" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
    fi
    
    TAIL_PID=""
    LOGIN_PID=""
    LOGIN_OUTPUT=""
}

# ==========================================================
# Ambiente
# ==========================================================

require_command() {
    local name="$1" message="$2"
    command -v "$name" >/dev/null 2>&1 || die 127 "$message"
}

log_environment() {
    log "setup iniciado"
    log "user: $(id -un)"
    log "HOME: $HOME"
    log "CODEX_HOME: $CODEX_HOME"
    log "PATH: $PATH"
}

prepare_environment() {
    local root status bootstrap
    local sub_path=".ai"
    local script_rel=".ai/bootstrap-ai-full.sh"
    # 🔓 evita "dubious ownership" quando o dono do repositório é outro UID
    local -a GIT=(git -c safe.directory='*')

    require_command codex   "codex não encontrado"
    require_command git     "git não encontrado"
    require_command python3 "python3 não está instalado no container"

    # 📁 1. Descobrir a raiz do projeto pelo git
    root="$("${GIT[@]}" -C "$WORKSPACE" rev-parse --show-toplevel 2>/dev/null)" || {
        error "❌ $WORKSPACE não é um repositório git"
        return 1
    }
    log "📁 raiz do projeto: $root"

    # 🧩 2. Conferir se o submodule existe e está baixado
    status="$("${GIT[@]}" -C "$root" submodule status -- "$sub_path" 2>/dev/null || true)"
    [ -n "$status" ] || {
        error "❌ submodule '$sub_path' não está registrado no .gitmodules"
        return 1
    }

    if [[ "$status" == -* ]]; then
        log "📥 submodule '$sub_path' não inicializado, baixando..."
        "${GIT[@]}" -C "$root" submodule update --init --recursive -- "$sub_path" || {
            error "❌ falha ao baixar o submodule '$sub_path'"
            return 1
        }
    fi

    # 🔍 3. Conferir se o script existe
    bootstrap="$root/$script_rel"
    [ -f "$bootstrap" ] || {
        error "❌ $bootstrap não encontrado"
        return 1
    }
    bash "$bootstrap" codex || true
    log "✅ CODEX_HOME pronto: $CODEX_HOME"    
    return 0
}

# ==========================================================
# Autenticação
# ==========================================================

is_authenticated() {
    codex login status >/dev/null 2>&1
}

start_login() {
    cleanup_login
    LOGIN_OUTPUT="$(mktemp)"
    codex login --device-auth > "$LOGIN_OUTPUT" 2>&1 &
    LOGIN_PID=$!

    # Espelha a saída do login no terminal.
    tail -f "$LOGIN_OUTPUT" &
    TAIL_PID=$!
}

login_is_running() {
    kill -0 "$LOGIN_PID" 2>/dev/null
}

extract_device_codev1() {
    sed 's/\x1b\[[0-9;]*m//g' "$LOGIN_OUTPUT" \
        | grep -Eo '[A-Z0-9]{4,6}-[A-Z0-9]{4,6}' \
        | tail -n 1 \
        || true
}

extract_device_code() {
    sed 's/\x1b\[[0-9;]*m//g' "$LOGIN_OUTPUT" \
        | grep -E '^[[:space:]]*[A-Z0-9]{4,6}-[A-Z0-9]{4,6}[[:space:]]*$' \
        | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
        | head -n 1 \
        || true
}

wait_for_device_code() {
    local attempt
    local code

    for ((attempt = 0; attempt < DEVICE_CODE_TIMEOUT_SECONDS; attempt++)); do
        code="$(extract_device_code)"

        if [[ -n "$code" ]]; then
            printf '%s\n' "$code"
            return 0
        fi

        if ! login_is_running; then
            error "o processo de login terminou antes de gerar o código"
            return 1
        fi

        sleep 1
    done

    error "tempo esgotado esperando o device code"
    return 1
}

open_browser() {
    local url="$1" helper

    # 🐍 1. Tentativa via Python
    if command -v python3 >/dev/null 2>&1 && [[ -n "${BROWSER:-}" ]]; then
        timeout 10 python3 -c \
            'import sys, webbrowser; sys.exit(0 if webbrowser.open(sys.argv[1]) else 1)' \
            "$url" >/dev/null 2>&1 </dev/null && return 0
    fi

    # 🧩 2. Fallback: localizar o helper browser.sh
    helper="${BROWSER:-}"
    if [[ ! -x "$helper" || "$helper" != *browser.sh ]]; then
        helper="$(/bin/ls -t "$HOME"/.vscode-server/bin/*/bin/helpers/browser.sh 2>/dev/null | head -n 1 || true)"
    fi
    [[ -n "$helper" ]] || return 1

    timeout 10 "$helper" "$url" >/dev/null 2>&1 </dev/null && return 0

    return 1
}

publish_device_auth() {
    local code="$1"
    local tmp_file="$DEVICE_AUTH_FILE.tmp"

    log "publicando device code: [$code]"

    cat >"$tmp_file" <<EOT
{
    "url": "$DEVICE_URL",
    "code": "$code"
}
EOT

    chmod 600 "$tmp_file"
    mv -f "$tmp_file" "$DEVICE_AUTH_FILE"
    sleep 2
    log "device-auth publicado em: $DEVICE_AUTH_FILE"
    
    read_device_code_from_file    
    copy_to_clipboard

    # ------------------------------------------------------
    # Abre o navegador
    # ------------------------------------------------------
    log "abrindo navegador..."
    if open_browser "$DEVICE_URL"; then

        log "navegador aberto no host"
    else
        log "não foi possível abrir o navegador automaticamente"
    fi
    log "abra: $DEVICE_URL"
}

# ------------------------------------------------------
# Clipboard
# ------------------------------------------------------
# 📄 Lê o código do device-auth.json (fonte da verdade).
read_device_code_from_file() {
    [[ -f "$DEVICE_AUTH_FILE" ]] || return 1
    python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["code"])' \
        "$DEVICE_AUTH_FILE" 2>/dev/null
}

copy_to_clipboard() {
    local code

    code="$(read_device_code_from_file)" || return 1

    printf '\033]52;c;%s\a' \
        "$(printf '%s' "$code" | base64 | tr -d '\n')" > /dev/tty
}

authenticate_with_device_code() {
    local device_code

    log "autenticação necessária"
    log "iniciando device authentication..."
    start_login

    log "aguardando device code..."
    device_code="$(wait_for_device_code)" || exit 1
    log "device code detectado: [$device_code]"

    publish_device_auth "$device_code"
    log "solicitação enviada para VS Code"
    log "navegador será aberto no host"
    log "aguardando autenticação..."

    wait "$LOGIN_PID" || die 1 "autenticação falhou"
    log "autenticação concluída"

    cleanup_login
}

ensure_authenticated() {
    log "verificando autenticação..."

    if is_authenticated; then
        log "autenticação OK"
    else
        authenticate_with_device_code
    fi
}


# ==========================================================
# Trust
# ==========================================================

is_workspace_trusted() {
    grep -Fq "[projects.\"$WORKSPACE\"]" "$CODEX_CONFIG"
}

trust_workspace() {
    cat >>"$CODEX_CONFIG" <<EOT

[projects."$WORKSPACE"]
trust_level = "trusted"
EOT
}

ensure_workspace_trusted() {
    log "configurando trust..."

    if [[ ! -w "$CODEX_CONFIG" ]]; then
        log "AVISO: $CODEX_CONFIG não gravável, pulando trust"
        return 0
    fi

    if grep -Fq "[projects.\"$WORKSPACE\"]" "$CODEX_CONFIG"; then
        log "trust já configurado"
    else
        printf '\n[projects."%s"]\ntrust_level = "trusted"\n' "$WORKSPACE" >> "$CODEX_CONFIG"
        log "$WORKSPACE marcado como trusted"
    fi
}

# ==========================================================
# Configuração
# ==========================================================

validate_toml_files() {
    log "validando TOML..."
    local files=() f
    for f in "$@"; do [[ -f "$f" ]] && files+=("$f"); done
    [[ ${#files[@]} -gt 0 ]] || return 0

    python3 - "${files[@]}" <<'PY'
import sys, tomllib
for path in sys.argv[1:]:
    with open(path, "rb") as f:
        tomllib.load(f)
    print(f"[codex] TOML válido: {path}")
PY
}

# ==========================================================
# Main
# ==========================================================

main() {
    trap 'on_error $? $LINENO "$BASH_COMMAND"' ERR
    trap cleanup_login EXIT

    log_environment
    prepare_environment
    ensure_authenticated
    ensure_workspace_trusted
    validate_toml_files "$CODEX_CONFIG"

    log "configuração concluída"
    log "setup finalizado"

    # exec substitui o processo e o trap EXIT não dispara,
    # então limpamos explicitamente antes.
    cleanup_login
    trap - EXIT

    if [[ $# -gt 0 ]]; then
        exec "$@"
    fi
}

main "$@"