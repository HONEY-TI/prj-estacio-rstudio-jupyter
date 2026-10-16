FROM alexfariakof/node-base:latest AS node
FROM apache/spark:3.5.1 AS spark

# =============================================================================
# Imagem final
# =============================================================================
FROM alexfariakof/r-packages:latest AS final

# Falha o build se qualquer comando de um pipe falhar
#SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# -----------------------------------------------------------------------------
# Argumentos de build
# -----------------------------------------------------------------------------
ARG EZA_VERSION=0.23.4
ARG JUPYTER_NOTEBOOK_DIR=""
ARG PROJECT_WORKSPACE=""
ARG JUPYTER_IP=0.0.0.0
ARG JUPYTER_PORT=8888
ARG JUPYTER_TOKEN=""
ARG JUPYTER_PASSWORD_REQUIRED=False
ARG JUPYTER_ALLOW_ORIGIN="*"

# -----------------------------------------------------------------------------
# Variáveis de ambiente
# -----------------------------------------------------------------------------
ENV TZ=America/Sao_Paulo \
    DEBIAN_FRONTEND=noninteractive \
    USERNAME=rstudio \
    SPARK_HOME=/opt/spark \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    PYSPARK_PYTHON=/opt/venv/bin/python \
    PYSPARK_DRIVER_PYTHON=/opt/venv/bin/python \
    PATH="/opt/spark/bin:/opt/spark/sbin:/opt/venv/bin:/usr/local/bin:${PATH}" \
    JUPYTER_NOTEBOOK_DIR="${JUPYTER_NOTEBOOK_DIR}" \
    PROJECT_WORKSPACE="${PROJECT_WORKSPACE}" \
    JUPYTER_IP="${JUPYTER_IP}" \
    JUPYTER_PORT="${JUPYTER_PORT}" \
    JUPYTER_TOKEN="${JUPYTER_TOKEN}" \
    JUPYTER_PASSWORD_REQUIRED="${JUPYTER_PASSWORD_REQUIRED}" \
    JUPYTER_ALLOW_ORIGIN="${JUPYTER_ALLOW_ORIGIN}"

# =============================================================================
# Spark
# =============================================================================
COPY --from=spark /opt/spark /opt/spark

# =============================================================================
# Dependências do sistema e eza
# =============================================================================
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        curl \
        zsh \
        ca-certificates \
        openjdk-17-jre-headless \
    && ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && curl -fsSL \
        "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz" \
        | tar -xzf - -C /usr/local/bin \
    && chmod +x /usr/local/bin/eza \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Node.js e npm
# =============================================================================
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# =============================================================================
# Ambiente Python (venv + pacotes + permissões)
# =============================================================================
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/venv/bin/pip install --no-cache-dir \
        jupyterlab \
        notebook \
        ipykernel \
        pandas \
        numpy \
        matplotlib \
        seaborn \
        scikit-learn \
        polars \
        pyarrow \
        jupyterlab-git \
        plotly \
        mrjob \
        black \
        flake8 \
        pytest \
        pyspark==3.5.1 \
    && chown -R rstudio:rstudio /opt/venv

# Registra o kernel R depois que o Jupyter estiver instalado.
# Os pacotes R são herdados da imagem alexfariakof/r-packages.
RUN R -e "IRkernel::installspec(user = FALSE)"

# =============================================================================
# Variáveis do R / Spark
# =============================================================================
RUN printf '%s\n' \
        "JAVA_HOME=${JAVA_HOME}" \
        "SPARK_HOME=${SPARK_HOME}" \
        "PYSPARK_PYTHON=${PYSPARK_PYTHON}" \
        "PYSPARK_DRIVER_PYTHON=${PYSPARK_DRIVER_PYTHON}" \
        >> /usr/local/lib/R/etc/Renviron.site

# =============================================================================
# Shell global: bash (/etc/bash.bashrc)
# =============================================================================
RUN cat >> /etc/bash.bashrc <<'EOF'

export HISTFILE="$HOME/shell_history/.bash_history"
export VIRTUAL_ENV="/opt/venv"
export PYSPARK_PYTHON="${VIRTUAL_ENV}/bin/python"
export PYSPARK_DRIVER_PYTHON="${VIRTUAL_ENV}/bin/python"
export PATH="/bin:/usr/local/bin:/usr/local/sbin:${VIRTUAL_ENV}/bin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:$HOME/.local/bin:$PATH"

# =========================================================
# ALIASES
# =========================================================
alias cls='clear'
alias py='python3'
alias ll='eza -l -h --group --group-directories-first'
alias la='eza -la -hs --group --group-directories-first'
alias lt='eza --tree --level=2 --group --group-directories-first'

function ls() {
    command eza \
        -la \
        -h \
        --group \
        --group-directories-first \
        --color=auto \
        "$@"
}

function lsh() {
    local dir="${1:-.}"

    command eza \
        -la \
        -h \
        --group \
        --group-directories-first \
        --sort=size \
        --color=auto \
        "$dir"
}


# ==========================================
# VENV + GIT BRANCH NO PROMPT
# ==========================================
MY_VENV="/opt/venv"

parse_git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null)

    [ -n "$branch" ] && printf " (%s)" "$branch"
}

set_venv_prompt() {
    local venv_prompt=""

    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        venv_prompt='\[\e[1;31m\](venv)\[\e[0m\] '
    fi

    PS1='\[\e[1;32m\]┌──\[\e[0m\] '"$venv_prompt"\
'\[\e[0;37m\](\[\e[1;34m\]\u\[\e[0;37m\]㉿\[\e[1;32m\]\h\[\e[0;37m\])\[\e[0m\]-'\
'\[\e[0;37m\][\w\[\e[1;33m\]$(parse_git_branch)\[\e[0;37m\]]\[\e[0m\]'\
'\n'\
'\[\e[1;32m\]└─\[\e[0m\]\$ '
}


function activate() {
    if [ -f "$MY_VENV/bin/activate" ]; then
        source "$MY_VENV/bin/activate"
        set_venv_prompt
    else
        echo "Erro: virtualenv não encontrado em $MY_VENV"
        return 1
    fi
}

function desactive() {
    if [[ -n "$VIRTUAL_ENV" ]] && type deactivate >/dev/null 2>&1; then
        deactivate
        set_venv_prompt
    else
        echo "Nenhum virtualenv ativo."
    fi
}

set_venv_prompt
EOF

# =============================================================================
# Shell global: zsh (/etc/zsh/zshrc)
# =============================================================================
RUN cat >> /etc/zshrc <<'EOF'
export HISTFILE="$HOME/shell_history/.zsh_history"
export VIRTUAL_ENV="/opt/venv"
export PYSPARK_PYTHON="${VIRTUAL_ENV}/bin/python"
export PYSPARK_DRIVER_PYTHON="${VIRTUAL_ENV}/bin/python"
export PATH="/bin:/usr/local/bin:/usr/local/sbin:${VIRTUAL_ENV}/bin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:$HOME/.local/bin:$PATH"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=20000

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt PROMPT_SUBST

alias cls='clear'
alias py='python3'
alias ll='eza -lh --group --group-directories-first'
alias la='eza -lah --group --group-directories-first'
alias lt='eza --tree --level=2 --group'


function ls() {
    command eza \
        -la \
        -h \
        --group \
        --group-directories-first \
        --color=auto \
        "$@"
}

function lsh() {
    local dir="${1:-.}"

    command eza \
        -la \
        -h \
        --group \
        --group-directories-first \
        --sort=size \
        --color=auto \
        "$dir"
}

MY_VENV="/opt/venv"

activate() {
    if [[ -f "$MY_VENV/bin/activate" ]]; then
        source "$MY_VENV/bin/activate"
    else
        echo "Erro: virtualenv não encontrado em $MY_VENV"
        return 1
    fi
}

desactive() {
    if [[ -n "$VIRTUAL_ENV" ]] && type deactivate >/dev/null 2>&1; then
        deactivate
    else
        echo "Nenhum virtualenv ativo."
    fi
}

set_prompt() {
    local git_branch
    git_branch=$(git branch --show-current 2>/dev/null)

    PROMPT=""
    PROMPT+="%F{%(#.blue.green)}┌── "

    if [[ -n "$VIRTUAL_ENV" ]]; then
        PROMPT+="%F{red}%B($(basename "$VIRTUAL_ENV"))%b%f "
    fi

    PROMPT+="(%B%F{%(#.red.blue)}%n㉿%m%b%F{%(#.blue.green)})"
    PROMPT+="-[%B%F{reset}%~%b%F{%(#.blue.green)}"

    if [[ -n "$git_branch" ]]; then
        PROMPT+=" %F{yellow}%B(${git_branch})%b%F{%(#.blue.green)}"
    fi

    PROMPT+="]"
    PROMPT+=$'\n'
    PROMPT+="└─%B%(#.%F{red}#.%F{blue}\$)%b%F{reset} "
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd set_prompt
EOF


# Copia o Bash global para o usuário rstudio
RUN cp /etc/bash.bashrc /home/rstudio/.bashrc \
    && chown rstudio:rstudio /home/rstudio/.bashrc

# Copia o zsh global para o usuário rstudio
RUN cp /etc/zshrc /home/rstudio/.zshrc \
    && chown rstudio:rstudio /home/rstudio/.zshrc
RUN chsh -s /bin/zsh 2>/dev/null || true;

# =============================================================================
# JupyterLab como serviço s6
# =============================================================================
RUN mkdir -p /etc/services.d/jupyter \
    && cat > /etc/services.d/jupyter/run <<'JUPYTER_RUN'
#!/usr/bin/with-contenv bash
set -e

APP_USER="${USERNAME:-rstudio}"
export HOME="/home/${APP_USER}"

NOTEBOOK_DIR="${JUPYTER_NOTEBOOK_DIR:-${PROJECT_WORKSPACE:-/workspace}}"
[ -d "${NOTEBOOK_DIR}" ] || NOTEBOOK_DIR="${HOME}"

cd "${NOTEBOOK_DIR}"

exec s6-setuidgid "${APP_USER}" \
    /opt/venv/bin/jupyter lab \
    --ip="${JUPYTER_IP:-0.0.0.0}" \
    --port="${JUPYTER_PORT:-8888}" \
    --no-browser \
    --notebook-dir="${NOTEBOOK_DIR}" \
    --IdentityProvider.token="${JUPYTER_TOKEN}" \
    --PasswordIdentityProvider.hashed_password='' \
    --ServerApp.password='' \
    --ServerApp.password_required="${JUPYTER_PASSWORD_REQUIRED}" \
    --ServerApp.allow_origin="${JUPYTER_ALLOW_ORIGIN}"
JUPYTER_RUN

RUN chmod 755 /etc/services.d/jupyter/run

# =============================================================================
# Troca automática para rstudio em shells interativos
# =============================================================================
RUN cat > /usr/local/sbin/auto-switch-user.sh <<'AUTOSWITCH'
#!/usr/bin/env bash

case $- in
    *i*) ;;
    *) return 0 2>/dev/null || exit 0 ;;
esac

TARGET="rstudio"
CURRENT="$(id -un 2>/dev/null || echo unknown)"

if [ "${CURRENT}" = "${TARGET}" ] || ! id "${TARGET}" >/dev/null 2>&1; then
    return 0 2>/dev/null || exit 0
fi

if [ "$(id -u)" = "0" ]; then
    echo "Auto-switch: ${CURRENT} -> ${TARGET}"
    exec su - "${TARGET}"
elif command -v sudo >/dev/null 2>&1 \
    && sudo -n -u "${TARGET}" true 2>/dev/null; then
    exec sudo -n -u "${TARGET}" -i
else
    echo "Aviso: sem permissão para trocar para ${TARGET}."
fi
AUTOSWITCH

RUN chmod 755 /usr/local/sbin/auto-switch-user.sh \
    && echo '[ -f /usr/local/sbin/auto-switch-user.sh ] && . /usr/local/sbin/auto-switch-user.sh' >> /etc/bash.bashrc \
    && mkdir -p /etc/zsh \
    && touch /etc/zsh/zshrc \
    && echo '[ -f /usr/local/sbin/auto-switch-user.sh ] && . /usr/local/sbin/auto-switch-user.sh' >> /etc/zsh/zshrc