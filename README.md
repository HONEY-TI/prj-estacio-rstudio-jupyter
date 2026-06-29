# 🚀 Plataforma Data Science + Apache Spark + RStudio + Jupyter

## 📌 Visão Geral

Ambiente integrado para:
* 🧪 RStudio Server
* 🐍 Python + JupyterLab
* ⚡ Apache Spark Cluster
* 🔥 PySpark
* 📦 Docker Compose
* 🖥️ VS Code DevContainer

---

# 🏗️ Arquitetura Macro
```mermaid
flowchart TB
    U[👤 Usuário]
    VS[🖥️ VS Code DevContainer]
    R[📊 RStudio Container
    R + Python + Jupyter]
    SM[⚡ Spark Master
    spark://spark-master:7077]
    SW[⚙️ Spark Worker
    Executor]
    FS[📂 Workspace]
    U --> VS
    VS --> R
    R --> SM
    SM --> SW
    R --> FS
    SW --> FS
```

---

# 🧩 Arquitetura Micro - RStudio
```mermaid
flowchart LR
subgraph RSTUDIO["📊 rstudio-dev-base"]
RS[RStudio Server
8787]
JL[JupyterLab
8888]
PY[Python VirtualEnv
/opt/venv]
PS[PySpark]
SP[Apache Spark
/opt/spark]
end
RS --> PY
JL --> PY
PY --> PS
PS --> SP
```

---

# ⚡ Arquitetura da Plataforma

> Este diagrama representa a arquitetura de execução dos containers Docker, demonstrando a rede interna `spark-network`, o container de desenvolvimento RStudio atuando com Spark Driver e a comunicação com o cluster Spark Standalone composto pelo Master e Worker.
> 
## 1. Diagrama de Arquitetura Docker Spark + RStudio
```mermaid
flowchart LR
R[📊 rstudio-dev-base]
M[⚡ spark-master]
W[⚙️ spark-worker]
NET{{🐳 spark-network}}
R --- NET
M --- NET
W --- NET
R -->|spark://spark-master:7077| M
M --> W
```

## 2. Diagrama de Arquitetura Spark Runtime
```mermaid
flowchart TD
APP[🐍 Aplicação PySpark]
DRIVER[🧠 Spark Driver]
MASTER[⚡ Spark Master]
WORKER[⚙️ Spark Worker]
APP --> DRIVER
DRIVER --> MASTER
MASTER --> WORKER
WORKER --> DRIVER
```

---

# 🔄 Sequência de Execução PySpark
```mermaid
sequenceDiagram
participant User as 👤 Usuário
participant R as 📊 RStudio/Jupyter
participant Driver as 🧠 Driver
participant Master as ⚡ Master
participant Worker as ⚙️ Worker
User->>R: Executa código PySpark
R->>Driver: Cria SparkSession
Driver->>Master: Solicita recursos
Master->>Worker: Aloca Executor
Worker-->>Driver: Recursos disponíveis
Driver->>Worker: Executa processamento
Worker-->>R: Retorna resultado
R-->>User: Exibe dados
```

---

# 🚀 Inicialização do Container
```mermaid
sequenceDiagram
participant Docker
participant Entry as 🚪 entrypoint.sh
participant User as 👤 rstudio
participant Jupyter as 📒 Jupyter
participant Init as 🔧 rocker init
Docker->>Entry: inicia container
Entry->>User: muda usuário
Entry->>Jupyter: inicia JupyterLab
Entry->>Init: inicia RStudio
Init->>Docker: mantém container ativo
```

---

# 🔁 Fluxo do Entrypoint
```mermaid
flowchart TD
START[🚀 Container iniciado]
CHECK{Existe comando?}
CHECK -->|Não| JUPYTER[📒 Iniciar Jupyter]
CHECK -->|Sim| CMD[Executar comando]
JUPYTER --> INIT[🔧 /init]
INIT --> END[Container ativo]
CMD --> END
```

---

# ☕ Java e Apache Spark
Spark 3.5.x utiliza melhor:
```
Spark 3.5.1
      |
      |
Java 17 LTS
      |
      |
PySpark
      |
      |
Python
```
Configuração:
```yaml
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

## ⚠️ Java 26
Evitar:
```
openjdk-26
```
Motivo:
* incompatibilidade JVM
* bibliotecas Spark podem falhar
* versão fora do ciclo LTS
Recomendado:
```
Java 17
   +
Spark 3.5
   +
Python 3
```

---

# 🌐 Portas
| Porta | Serviço          |
| ----- | ---------------- |
| 8787  | RStudio          |
| 8888  | Jupyter          |
| 7077  | Spark Master RPC |
| 8080  | Spark Master UI  |
| 8081  | Spark Worker UI  |

---

# 🔗 Comunicação Docker
Dentro da rede Docker:
```
rstudio
   |
   |
spark://spark-master:7077
   |
   |
spark-worker
```
Não usar:
```
spark://localhost:7077
```
porque localhost dentro do container aponta para o próprio container.

---

# 📂 Volumes
```mermaid
flowchart LR
HOST[💻 Host]
WORK[📂 workspace]
R[📊 /home/rstudio/workspace]
SP[⚡ /workspace]
HOST --> WORK
WORK --> R
WORK --> SP
```

---

# 🗄️ Futuro: HDFS + Cassandra
Arquitetura:
```mermaid
flowchart TD
SPARK[⚡ Spark]
NN[🗂️ NameNode]
DN[💾 DataNode]
CAS[🪨 Cassandra]
SPARK --> NN
NN --> DN
SPARK --> CAS
```

---

# 📌 Componentes atuais

✅ RStudio Server
✅ JupyterLab
✅ Python Virtual Environment
✅ PySpark
✅ Spark Master
✅ Spark Worker
✅ Docker Compose
✅ VS Code DevContainer

Próximas integrações:
➡️ Hadoop HDFS
➡️ Cassandra Connector
➡️ Kafka
➡️ Delta Lake
➡️ Spark Streaming