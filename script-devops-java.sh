#!/bin/bash
set -e

echo "[DimDim] Iniciando script de deploy..."
# ============================
# VARIÁVEIS
# ============================
export RESOURCE_GROUP_NAME="rg-dimdim-cloud"
export WEBAPP_NAME="dimdim-cloud-app"
export APP_SERVICE_PLAN="planDimDimCloud"
export LOCATION="brazilsouth"
export RUNTIME="JAVA:17-java17"
export GITHUB_REPO_NAME="andrealtobelli/java-cloud-cp5"
export BRANCH="main"
export APP_INSIGHTS_NAME="ai-dimdim-cloud"

# Carregar variáveis do banco, se existir arquivo .env.db
if [ -f ./.env.db ]; then
  source ./.env.db
fi

echo "[DimDim] Carregando variáveis do banco de dados..."
: "${RG_DB_NAME:=rg-dimdim-cloud-db}"
: "${DB_LOCATION:=brazilsouth}"
: "${SERVER_NAME:=sqlserver-dimdim-cloud-$RANDOM$RANDOM}"
: "${DB_USERNAME:=admjava}"
: "${DB_PASSWORD:=DimDim_321}"
: "${DB_NAME:=DimDimGestao}"

az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ServiceLinker
az provider register --namespace Microsoft.Sql
az extension add --name application-insights --allow-preview true || true
echo "[DimDim] Providers e extensões registrados."

if ! command -v az >/dev/null 2>&1; then
  echo "ERRO: Azure CLI (az) não encontrado." >&2
  exit 1
fi
if ! command -v sqlcmd >/dev/null 2>&1 && ! command -v pwsh >/dev/null 2>&1; then
  echo "ERRO: Nem sqlcmd nem pwsh encontrados. Instale o sqlcmd (ou use PowerShell com módulo SqlServer)." >&2
  exit 1
fi
echo "[DimDim] Pré-checks de dependências OK."

az group create --name $RG_DB_NAME --location "$DB_LOCATION"
az group create --name $RESOURCE_GROUP_NAME --location "$LOCATION"
echo "[DimDim] Grupos de recursos criados."

az sql server create \
  --name $SERVER_NAME \
  --resource-group $RG_DB_NAME \
  --location "$DB_LOCATION" \
  --admin-user $DB_USERNAME \
  --admin-password $DB_PASSWORD \
  --enable-public-network true

az sql db create \
  --resource-group $RG_DB_NAME \
  --server $SERVER_NAME \
  --name $DB_NAME \
  --service-objective Basic \
  --backup-storage-redundancy Local \
  --zone-redundant false

az sql server firewall-rule create \
  --resource-group $RG_DB_NAME \
  --server $SERVER_NAME \
  --name liberaGeral \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 255.255.255.255
echo "[DimDim] Banco de dados SQL criado e firewall liberado."

TMP_SQL=$(mktemp)
cat >"$TMP_SQL" <<'SQL'
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
  BEGIN TRAN;
  IF OBJECT_ID('dbo.Funcionario','U') IS NOT NULL DROP TABLE dbo.Funcionario;
  IF OBJECT_ID('dbo.Empresa','U') IS NOT NULL DROP TABLE dbo.Empresa;
  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO

BEGIN TRAN;
CREATE TABLE dbo.Empresa (
  id BIGINT IDENTITY(1,1) PRIMARY KEY,
  nome NVARCHAR(255) NOT NULL
);

CREATE TABLE dbo.Funcionario (
  id BIGINT IDENTITY(1,1) PRIMARY KEY,
  nome NVARCHAR(255) NOT NULL,
  cargo NVARCHAR(255) NOT NULL,
  empresa_id BIGINT NOT NULL,
  CONSTRAINT FK_Funcionario_Empresa FOREIGN KEY (empresa_id) REFERENCES dbo.Empresa(id)
);
COMMIT TRAN;
GO

-- Seed de exemplo
INSERT INTO dbo.Empresa (nome) VALUES (N'DimDim Tecnologia');
INSERT INTO dbo.Funcionario (nome, cargo, empresa_id) VALUES (N'João Silva', N'Analista', 1);
INSERT INTO dbo.Funcionario (nome, cargo, empresa_id) VALUES (N'Maria Souza', N'Desenvolvedora', 1);
GO
SQL

echo "==> Aplicando schema/seed no Azure SQL: $SERVER_NAME/$DB_NAME"
if command -v sqlcmd >/dev/null 2>&1; then
  sqlcmd \
    -S "${SERVER_NAME}.database.windows.net" \
    -d "$DB_NAME" \
    -U "$DB_USERNAME" \
    -P "$DB_PASSWORD" \
    -l 60 \
    -b \
    -i "$TMP_SQL"
else
  echo "sqlcmd não encontrado, usando pwsh + Invoke-Sqlcmd como fallback..."
  pwsh -NoLogo -NoProfile -Command "
    if (-not (Get-Module -ListAvailable -Name SqlServer)) {
      try { Install-Module -Name SqlServer -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop } catch { Write-Error 'Falha ao instalar módulo SqlServer'; exit 1 }
    }
    try {
      Invoke-Sqlcmd -ServerInstance '${SERVER_NAME}.database.windows.net' -Database '${DB_NAME}' -Username '${DB_USERNAME}' -Password '${DB_PASSWORD}' -InputFile '${TMP_SQL}' -ConnectionTimeout 60 -QueryTimeout 300
    } catch {
      Write-Error $_.Exception.Message; exit 1
    }
  "
fi
echo "[DimDim] Script SQL executado com sucesso."

rm -f "$TMP_SQL"

az monitor app-insights component create \
  --app $APP_INSIGHTS_NAME \
  --location "$LOCATION" \
  --resource-group $RESOURCE_GROUP_NAME \
  --application-type web

CONNECTION_STRING=$(az monitor app-insights component show \
  --app $APP_INSIGHTS_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --query connectionString \
  --output tsv)
echo "[DimDim] Application Insights criado e configurado."

az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP_NAME \
  --location "$LOCATION" \
  --sku F1 \
  --is-linux

az webapp create \
  --name $WEBAPP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --plan $APP_SERVICE_PLAN \
  --runtime "$RUNTIME"

az resource update \
  --resource-group $RESOURCE_GROUP_NAME \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --name scm \
  --parent sites/$WEBAPP_NAME \
  --set properties.allow=true
echo "[DimDim] App Service Plan e WebApp criados. SCM habilitado."

JDBC_CONNECTION_STRING="jdbc:sqlserver://${SERVER_NAME}.database.windows.net:1433;database=${DB_NAME};user=${DB_USERNAME}@${SERVER_NAME};password=${DB_PASSWORD};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"

az webapp config appsettings set \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --settings \
    APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING" \
    ApplicationInsightsAgent_EXTENSION_VERSION="~3" \
    XDT_MicrosoftApplicationInsights_Mode="Recommended" \
    XDT_MicrosoftApplicationInsights_PreemptSdk="1" \
    SPRING_DATASOURCE_URL="$JDBC_CONNECTION_STRING" \
    SPRING_DATASOURCE_USERNAME="$DB_USERNAME" \
    SPRING_DATASOURCE_PASSWORD="$DB_PASSWORD" \
    DB_SERVER="$SERVER_NAME.database.windows.net" \
    DB_DATABASE="$DB_NAME" \
    DB_USERNAME="$DB_USERNAME" \
    DB_PASSWORD="$DB_PASSWORD" \
    SPRING_PROFILES_ACTIVE="prod"

az webapp restart --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP_NAME

az monitor app-insights component connect-webapp \
    --app $APP_INSIGHTS_NAME \
    --web-app $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP_NAME
echo "[DimDim] Variáveis de ambiente configuradas e WebApp reiniciado. Application Insights conectado."

# ============================
# DEPLOY VIA GITHUB ACTIONS
# ============================
az webapp deployment github-actions add \
  --name $WEBAPP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --repo $GITHUB_REPO_NAME \
  --branch $BRANCH \
  --login-with-github

echo "[DimDim] Deploy via GitHub Actions configurado com sucesso!"
