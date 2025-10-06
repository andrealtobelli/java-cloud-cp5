# DimDim Cloud App - Gestão de Empresas e Funcionários

## 👥 Integrantes

- Leticia Cristina Dos Santos Passos RM: 555241
- André Rogério Vieira Pavanela Altobelli Antunes RM: 554764
- Enrico Figueiredo Del Guerra RM: 558604
- **Instituição**: FIAP - DevOps Tools & Cloud Computing

---

## 🚀 Tecnologias Utilizadas

- **Java 17** - Framework principal (Spring Boot)
- **Spring Boot** - Framework web e de persistência
- **Spring Data JPA** - ORM para acesso a dados
- **Thymeleaf** - Templates HTML dinâmicos
- **Azure SQL Database** - Banco de dados em nuvem (PaaS)
- **Azure App Service** - Hospedagem da aplicação
- **Azure CLI** - Criação de recursos via script
- **GitHub Actions** - CI/CD automatizado
- **Application Insights** - Monitoramento e telemetria

---

## 🏗️ Estrutura do Projeto

```
java-cloud-cp5/
├── src/
│   ├── main/
│   │   ├── java/com/dimdim/         # Código-fonte Java
│   │   └── resources/templates/     # Templates HTML (Thymeleaf)
│   └── test/                       # Testes automatizados
├── script-devops-java.sh           # Script de deploy Azure
├── pom.xml                         # Gerenciador de dependências Maven
└── README.md                       # Documentação
```

---

## 🚀 Passo a Passo para Deploy

### Pré-requisitos

1. **Azure CLI** instalado e configurado
2. **Git** instalado
3. **Conta Azure** ativa
4. **Conta GitHub**

### 1. Clone do Repositório

```bash
git clone https://github.com/andrealtobelli/java-cloud-cp5.git
cd java-cloud-cp5
```

### 2. Login no Azure

```bash
az login
```

### 3. Execução do Script de Deploy

```bash
# No Windows (PowerShell/Git Bash)
bash script-devops-java.sh

# No Linux/Mac
dos2unix script-devops-java.sh
chmod +x script-devops-java.sh
./script-devops-java.sh
```

### 4. Aguardar Deploy Automático

O script irá:
- Criar Resource Group
- Criar Azure SQL Server e Database
- Criar App Service Plan e App Service
- Configurar Connection String
- Executar script SQL para criar tabelas
- Inserir dados de exemplo
- Configurar GitHub Actions para CI/CD

### 5. Verificar Deploy

Após execução do script, acesse:
- **Web App**: https://dimdim-cloud-app.azurewebsites.net/empresas

---

## 📁 Arquivos de Script

- `script-devops-java.sh` - Script principal de deploy Azure
- `src/main/resources/application.properties` - Configuração do banco e Application Insights
- `script_bd.sql` - Script banco de dados

---

## 🎥 Demonstração em Vídeo

O vídeo demonstrativo inclui:

1. **Clone do repositório** do GitHub
2. **Execução do script-devops-java.sh** para deploy completo
3. **Criação e configuração** dos recursos Azure
4. **Demonstração completa do CRUD Web App** de empresas e funcionários
5. **Validação no banco de dados** de cada operação CRUD
6. **Integração completa** entre App e Database funcionando 100%

### Link do Vídeo:
**YouTube**: 

---

**Desenvolvido para FIAP - DevOps Tools & Cloud Computing**  
**Turma**: 3º Sprint - 2025
# Java