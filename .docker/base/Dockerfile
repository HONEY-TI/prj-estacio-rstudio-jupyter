FROM node:24.21.0-bookworm-slim AS node
FROM apache/spark:3.5.1 AS spark
FROM rocker/rstudio:latest

# =============================================================================
# Ambiente
# =============================================================================
COPY --from=spark /opt/spark /opt/spark
ENV SPARK_HOME=/opt/spark
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="/opt/spark/bin:/opt/spark/sbin:/opt/venv/bin:/usr/local/bin:${PATH}"
ENV PYSPARK_PYTHON=/opt/venv/bin/python
ENV PYSPARK_DRIVER_PYTHON=/opt/venv/bin/python

# =============================================================================
# Dependências do sistema
# =============================================================================
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        zsh \
        curl \
        git \
        eza \
        ca-certificates \
        openjdk-17-jre-headless \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Node.js 24 + npm (copiado da imagem node:24-slim, global para todos os usuários)
# =============================================================================
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# =============================================================================
# Venv Python
# =============================================================================
RUN python3 -m venv /opt/venv \
    && chown -R rstudio:rstudio /opt/venv

RUN /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install \
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
        pyspark==3.5.1

# =============================================================================
# Pacotes R
# =============================================================================
RUN R -e "install.packages( \
        c('tidyverse', 'languageserver', 'IRkernel', 'sparklyr', 'sampling', 'survey'), \
        repos = 'https://cloud.r-project.org/', \
        quiet = TRUE \
    )" \
    && R -e "IRkernel::installspec(user = FALSE)"

# =============================================================================
# Variáveis para o R (RStudio Server limpa o ambiente)
# =============================================================================
RUN printf '%s\n' \
        "JAVA_HOME=${JAVA_HOME}" \
        "SPARK_HOME=${SPARK_HOME}" \
        "PYSPARK_PYTHON=${PYSPARK_PYTHON}" \
        >> /usr/local/lib/R/etc/Renviron.site

# =============================================================================
# Shell global: bash (/etc/bash.bashrc)
# =============================================================================
RUN cat >> /etc/bash.bashrc <<'EOF'

export HISTFILE="$HOME/shell_history/.zsh_history"
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
source "$MY_VENV/bin/activate"
set_venv_prompt
EOF

# =============================================================================
# Shell global: zsh (/etc/zsh/zshrc)
# =============================================================================
RUN cat >> /etc/zsh/zshrc <<'EOF'
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

source "$MY_VENV/bin/activate"
autoload -Uz add-zsh-hook
add-zsh-hook precmd set_prompt
EOF
