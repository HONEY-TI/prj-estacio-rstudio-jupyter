#!/bin/bash
set -euo pipefail

readonly APP_USER="${USERNAME:-rstudio}"
readonly PROJECT_WORKSPACE="${WORKSPACE:-/workspace}"
readonly USER_HOME="/home/${APP_USER}"

# ── 🧰 Helpers de log ───────────────────────────────────────────────
log()  { echo "[entrypoint] ℹ️  $*"; }
ok()   { echo "[entrypoint] ✅ OK:    $*"; }
warn() { echo "[entrypoint] ⚠️  AVISO: $*" >&2; }
fail() { echo "[entrypoint] ❌ ERRO:  $*" >&2; exit 1; }
step() { echo "[entrypoint] ──────────────────────────────────────────"; echo "[entrypoint] $*"; }

# ── 🔍 1. Pré-requisitos ────────────────────────────────────────────
step "🔍 Passo 1/5: validando pré-requisitos"

[ "$(id -u)" -eq 0 ]               || fail "precisa rodar como root (UID atual: $(id -u))"
id "$APP_USER" &>/dev/null         || fail "usuário '$APP_USER' não existe"
[ -d "$PROJECT_WORKSPACE" ]        || fail "diretório '$PROJECT_WORKSPACE' não existe (volume montado?)"
[ -d "$USER_HOME" ]                || fail "home '$USER_HOME' não existe"
ok "👑 root, 👤 usuário '$APP_USER', 📁 workspace e 🏠 home encontrados"

# ── 🆔 2. Ler UID/GID ───────────────────────────────────────────────
step "🆔 Passo 2/5: lendo UID/GID"

HOST_UID=$(stat -c '%u' "$PROJECT_WORKSPACE")
HOST_GID=$(stat -c '%g' "$PROJECT_WORKSPACE")
CURRENT_UID=$(id -u "$APP_USER")
CURRENT_GID=$(id -g "$APP_USER")

log "📁 workspace  → UID:GID ${HOST_UID}:${HOST_GID}"
log "👤 $APP_USER  → UID:GID ${CURRENT_UID}:${CURRENT_GID}"

# ── 🔄 3. Realinhar UID/GID ─────────────────────────────────────────
step "🔄 Passo 3/5: realinhando UID/GID"

if [ "$HOST_GID" != "$CURRENT_GID" ]; then
    log "👥 ajustando GID: $CURRENT_GID → $HOST_GID"
    groupmod -o -g "$HOST_GID" "$APP_USER" || fail "groupmod falhou"
    [ "$(id -g "$APP_USER")" = "$HOST_GID" ] \
        && ok "👥 GID alterado para $HOST_GID" \
        || fail "GID continua $(id -g "$APP_USER"), esperado $HOST_GID"
else
    ok "👥 GID já estava correto ($CURRENT_GID)"
fi

if [ "$HOST_UID" != "$CURRENT_UID" ]; then
    log "👤 ajustando UID: $CURRENT_UID → $HOST_UID"
    usermod -o -u "$HOST_UID" "$APP_USER" || fail "usermod falhou"
    [ "$(id -u "$APP_USER")" = "$HOST_UID" ] \
        && ok "👤 UID alterado para $HOST_UID" \
        || fail "UID continua $(id -u "$APP_USER"), esperado $HOST_UID"
else
    ok "👤 UID já estava correto ($CURRENT_UID)"
fi

# ── 🔧 4. Corrigir permissões ───────────────────────────────────────
step "🔧 Passo 4/5: corrigindo permissões"

fix_owner() {
    local path="$1" recursive="${2:-yes}"

    if [ ! -e "$path" ]; then
        warn "📂 '$path' não existe, ignorando"
        return 0
    fi

    local flag=""
    [ "$recursive" = "yes" ] && flag="-R"

    if chown $flag "${APP_USER}:${APP_USER}" "$path"; then
        # Confere se o dono do próprio diretório está certo
        local owner
        owner=$(stat -c '%U' "$path")
        [ "$owner" = "$APP_USER" ] \
            && ok "🔑 chown $flag em '$path' (dono: $owner)" \
            || warn "chown rodou em '$path', mas o dono é '$owner'"
    else
        warn "chown falhou em '$path' (pode ser volume somente leitura)"
    fi
}

fix_owner "$USER_HOME"
fix_owner "$USER_HOME/.vscode-server"
fix_owner "$USER_HOME/.ssh"

# 🔐 ssh exige permissões restritas
if [ -d "$USER_HOME/.ssh" ]; then
    chmod 700 "$USER_HOME/.ssh" && ok "🔐 .ssh com permissão 700"
fi

# 🛡️ O workspace NÃO recebe chown recursivo (pode ser bind mount do host)
ok "🛡️ workspace '$PROJECT_WORKSPACE' mantido com dono original ${HOST_UID}:${HOST_GID}"

# ── 🔓 5. Liberar leitura de /tmp ───────────────────────────────────
step "🔓 Passo 5/5: liberando leitura de /tmp para '$APP_USER'"

grant_read() {
    local path="$1"

    if [ ! -d "$path" ]; then
        warn "📂 '$path' não existe, ignorando"
        return 0
    fi

    if command -v setfacl &>/dev/null; then
        # 📜 ACL atual + ACL padrão (herdada por novos arquivos/pastas)
        if setfacl -R -m "u:${APP_USER}:rX" "$path" 2>/dev/null \
           && setfacl -R -d -m "u:${APP_USER}:rX" "$path" 2>/dev/null; then
            ok "📜 ACL de leitura aplicada em '$path' para '$APP_USER'"
        else
            warn "setfacl falhou em '$path' (filesystem sem suporte a ACL?)"
        fi
    else
        warn "setfacl não encontrado, usando chmod o+rX (leitura para todos)"
        chmod -R o+rX "$path" 2>/dev/null \
            && ok "🔓 chmod o+rX aplicado em '$path'" \
            || warn "chmod falhou em '$path'"
    fi

    # 🧪 Confere se o usuário realmente consegue ler
    if su -s /bin/bash "$APP_USER" -c "ls '$path' >/dev/null 2>&1"; then
        ok "👀 '$APP_USER' consegue listar '$path'"
    else
        warn "🚫 '$APP_USER' ainda NÃO consegue listar '$path'"
    fi
}

grant_read /tmp

# ── 🐍 6. Instalar dependências Python ──────────────────────────────
step "🐍 Passo 6/6: instalando dependências Python (venv)"

readonly VENV_DIR="/opt/venv"
readonly REQ_FILE="/usr/local/share/requirements.txt"
readonly REQ_HASH_FILE="${VENV_DIR}/.requirements.sha256"

install_python_deps() {
    [ -x "${VENV_DIR}/bin/pip" ] || { warn "venv '${VENV_DIR}' não encontrado, ignorando"; return 0; }
    [ -f "$REQ_FILE" ]           || { warn "'$REQ_FILE' não encontrado, ignorando"; return 0; }

    local new_hash old_hash=""
    new_hash=$(sha256sum "$REQ_FILE" | awk '{print $1}')
    [ -f "$REQ_HASH_FILE" ] && old_hash=$(cat "$REQ_HASH_FILE")

    if [ "$new_hash" = "$old_hash" ]; then
        ok "📦 requirements já instalados (hash inalterado)"
        return 0
    fi

    log "📦 instalando requirements (isso pode demorar na primeira vez)..."

    # Garante que o venv pertence ao usuário (UID pode ter mudado no Passo 3)
    chown -R "${APP_USER}:${APP_USER}" "$VENV_DIR"

    if su -s /bin/bash "$APP_USER" -c \
        "'${VENV_DIR}/bin/pip' install --upgrade pip \
         && '${VENV_DIR}/bin/pip' install --no-cache-dir -r '${REQ_FILE}'"; then
        echo "$new_hash" > "$REQ_HASH_FILE"
        chown "${APP_USER}:${APP_USER}" "$REQ_HASH_FILE"
        ok "📦 dependências Python instaladas"
    else
        warn "pip install falhou (o container segue, mas o venv pode estar incompleto)"
    fi
}

install_python_deps

# ── 📋 Resumo final ─────────────────────────────────────────────────
step "📋 Resumo final"
log "👤 $(id "$APP_USER")"
log "🚀 Iniciando: $*"
exec "$@"