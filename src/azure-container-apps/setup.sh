# Set environment variables
RESOURCE_GROUP="storemanager-rg"
LOCATION="canadacentral"
CONTAINERAPPS_ENVIRONMENT="storemanager-env"
CONTAINERAPPS_LOG="storemanager-log"
CONTAINERAPPS_STORAGE_ACCOUNT="storemanagerstorage"
CONTAINERAPPS_STORAGE_CONTAINER="stateandactors"
CONTAINERAPPS_PUBSUB_NAMESPACE=storemanager$RANDOM
CONTAINERAPPS_PUBSUB_TOPIC="orders"

# az cli
az login
az upgrade
az extension add \
  --source https://workerappscliextension.blob.core.windows.net/azure-cli-extension/containerapp-0.2.0-py2.py3-none-any.whl
az provider register --namespace Microsoft.Web

# az resources
az group create \
  --name $RESOURCE_GROUP \
  --location "$LOCATION"

# Create Log Analytics
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $CONTAINERAPPS_LOG

LOG_ANALYTICS_WORKSPACE_CLIENT_ID=`az monitor log-analytics workspace show --query customerId -g $RESOURCE_GROUP -n $CONTAINERAPPS_LOG --out tsv`

LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET=`az monitor log-analytics workspace get-shared-keys --query primarySharedKey -g $RESOURCE_GROUP -n $CONTAINERAPPS_LOG --out tsv`

# Create an environment
az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
  --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET \
  --location "$LOCATION"

# Create an Azure Blob Storage Account to store state
az storage account create \
  --name $CONTAINERAPPS_STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" \
  --sku Standard_RAGRS \
  --kind StorageV2

STORAGE_ACCOUNT_KEY=`az storage account keys list --resource-group $RESOURCE_GROUP --account-name $CONTAINERAPPS_STORAGE_ACCOUNT --query '[0].value' --out tsv`
echo $STORAGE_ACCOUNT_KEY

# Create an Azure Service Bus namespace and topic
az servicebus namespace create --resource-group $RESOURCE_GROUP --name $CONTAINERAPPS_PUBSUB_NAMESPACE --location $LOCATION

az servicebus topic create --resource-group $RESOURCE_GROUP --namespace-name $CONTAINERAPPS_PUBSUB_NAMESPACE --name $CONTAINERAPPS_PUBSUB_TOPIC

## WARNING: How to retrieve service bus connection string from AZ?!!!

# Create Redis Cache
az redis create 
  --name storemanager6 
  --resource-group $RESOURCE_GROUP 
  --location $LOCATION 
  --sku Basic 
  --vm-size C0
  --enable-non-ssl-port
  --redis-version 6

# cd to azure-container-apps
# Create Actors App
az containerapp create \
  --name storemanageractors \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image khaledhikmat/store-manager-actors:1.0 \
  --target-port 6000 \
  --ingress 'external' \
  --min-replicas 1 \
  --max-replicas 1 \
  --enable-dapr \
  --dapr-app-port 6000 \
  --dapr-app-id storemanageractors \
  --dapr-components ./components/components.yaml

# Create Orders App
az containerapp create \
  --name storemanagerorders \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image khaledhikmat/store-manager-orders:1.0 \
  --target-port 6001 \
  --ingress 'external' \
  --min-replicas 1 \
  --max-replicas 1 \
  --enable-dapr \
  --dapr-app-port 6001 \
  --dapr-app-id storemanagerorders \
  --dapr-components ./components/components.yaml

# Create Entities App
az containerapp create \
  --name storemanagerentities \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image khaledhikmat/store-manager-entities:1.0 \
  --target-port 6002 \
  --ingress 'external' \
  --min-replicas 1 \
  --max-replicas 1 \
  --enable-dapr \
  --dapr-app-port 6002 \
  --dapr-app-id storemanagerentities \
  --dapr-components ./components/components.yaml

az monitor log-analytics query \
  --workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'storemanagerentities' | project ContainerAppName_s, Log_s, TimeGenerated | take 5" \
  --out table
  
az monitor log-analytics query \
  --workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'storemanagerorders' | project ContainerAppName_s, Log_s, TimeGenerated | take 5" \
  --out table

az monitor log-analytics query \
  --workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'storemanageractors' | project ContainerAppName_s, Log_s, TimeGenerated | take 5" \
  --out table

az monitor log-analytics query --workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'storemanagerentities' | project ContainerAppName_s, Log_s, TimeGenerated | take 100" --out table > entities.log
az monitor log-analytics query --workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'storemanagerorders' | project ContainerAppName_s, Log_s, TimeGenerated | take 100" --out table > orders.log
az monitor log-analytics query --workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'storemanageractors' | project ContainerAppName_s, Log_s, TimeGenerated | take 100" --out table > actors.log

# Create Hello Node App
az containerapp create \
  --name node-hello \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image khaledhikmat/node-hello-world-api:v1.0.3 \
  --target-port 8080 \
  --ingress 'external' \
  --min-replicas 1 \
  --max-replicas 1

Now this works - hitting the revision:
GET https://node-hello--lfg1i8s.ambitiousdesert-ef67c030.canadacentral.azurecontainerapps.io/health/liveness
GET https://node-hello--lfg1i8s.ambitiousdesert-ef67c030.canadacentral.azurecontainerapps.io/health/readiness
OR hitting the app:
https://node-hello.ambitiousdesert-ef67c030.canadacentral.azurecontainerapps.io/health/liveness

# Update Hello Node App to use DAPR
az containerapp update \
  --name node-hello \
  --resource-group $RESOURCE_GROUP \
  --image khaledhikmat/node-hello-world-api:v1.0.3 \
  --target-port 8080 \
  --ingress 'external' \
  --min-replicas 1 \
  --max-replicas 1 \
  --enable-dapr \
  --dapr-app-port 8080 \
  --dapr-app-id node-hello
