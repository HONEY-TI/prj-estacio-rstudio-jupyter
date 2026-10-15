FROM rocker/rstudio:latest
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libzmq3-dev \
        python3-jupyter-core \
        python3-jupyter-client \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages( \
    c('tidyverse', 'languageserver', 'IRkernel', 'sparklyr', 'sampling', 'survey'), \
    repos = 'https://cloud.r-project.org/' \
)"