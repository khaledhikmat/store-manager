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

{
  "createdAt": "2022-01-01T18:11:55.260000+00:00",
  "encryption": null,
  "id": "/subscriptions/0ba7fde9-7c4b-4693-96dd-65919b7692e8/resourceGroups/storemanager-rg/providers/Microsoft.ServiceBus/namespaces/storemanager3596",
  "identity": null,
  "location": "Canada Central",
  "metricId": "0ba7fde9-7c4b-4693-96dd-65919b7692e8:storemanager3596",
  "name": "storemanager3596",
  "provisioningState": "Succeeded",
  "resourceGroup": "storemanager-rg",
  "serviceBusEndpoint": "https://storemanager3596.servicebus.windows.net:443/",
  "sku": {
    "capacity": null,
    "name": "Standard",
    "tier": "Standard"
  },
  "tags": {},
  "type": "Microsoft.ServiceBus/Namespaces",
  "updatedAt": "2022-01-01T18:12:38.800000+00:00",
  "zoneRedundant": false
}

az servicebus topic create --resource-group $RESOURCE_GROUP --namespace-name $CONTAINERAPPS_PUBSUB_NAMESPACE --name $CONTAINERAPPS_PUBSUB_TOPIC
{
  "accessedAt": "0001-01-01T00:00:00",
  "autoDeleteOnIdle": "10675199 days, 2:48:05.477581",
  "countDetails": {
    "activeMessageCount": 0,
    "deadLetterMessageCount": 0,
    "scheduledMessageCount": 0,
    "transferDeadLetterMessageCount": 0,
    "transferMessageCount": 0
  },
  "createdAt": "2022-01-01T18:14:03.060000+00:00",
  "defaultMessageTimeToLive": "10675199 days, 2:48:05.477581",
  "duplicateDetectionHistoryTimeWindow": "0:10:00",
  "enableBatchedOperations": true,
  "enableExpress": false,
  "enablePartitioning": false,
  "id": "/subscriptions/0ba7fde9-7c4b-4693-96dd-65919b7692e8/resourceGroups/storemanager-rg/providers/Microsoft.ServiceBus/namespaces/storemanager3596/topics/orders",
  "location": "Canada Central",
  "maxSizeInMegabytes": 1024,
  "name": "orders",
  "requiresDuplicateDetection": false,
  "resourceGroup": "storemanager-rg",
  "sizeInBytes": 0,
  "status": "Active",
  "subscriptionCount": 0,
  "supportOrdering": true,
  "type": "Microsoft.ServiceBus/Namespaces/Topics",
  "updatedAt": "2022-01-01T18:14:03.227000+00:00"
}

## WARNING: How to retrieve service bus connection string from AZ?!!!

# Create Redis Cache
az redis create --name storemanager --resource-group $RESOURCE_GROUP --location $LOCATION --sku Basic --vm-size C0


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
{
  "configuration": {
    "activeRevisionsMode": "Multiple",
    "ingress": {
      "allowInsecure": false,
      "external": true,
      "fqdn": "storemanagerentities.ambitiousdesert-ef67c030.canadacentral.azurecontainerapps.io",
      "targetPort": 6002,
      "traffic": [
        {
          "latestRevision": true,
          "revisionName": null,
          "weight": 100
        }
      ],
      "transport": "Auto"
    },
    "registries": null,
    "secrets": null
  },
  "id": "/subscriptions/0ba7fde9-7c4b-4693-96dd-65919b7692e8/resourceGroups/storemanager-rg/providers/Microsoft.Web/containerApps/storemanagerentities",
  "kind": null,
  "kubeEnvironmentId": "/subscriptions/0ba7fde9-7c4b-4693-96dd-65919b7692e8/resourceGroups/storemanager-rg/providers/Microsoft.Web/kubeEnvironments/storemanager-env",
  "latestRevisionFqdn": "storemanagerentities--howowqq.ambitiousdesert-ef67c030.canadacentral.azurecontainerapps.io",
  "latestRevisionName": "storemanagerentities--howowqq",
  "location": "Canada Central",
  "name": "storemanagerentities",
  "provisioningState": "Succeeded",
  "resourceGroup": "storemanager-rg",
  "tags": null,
  "template": {
    "containers": [
      {
        "args": null,
        "command": null,
        "env": null,
        "image": "khaledhikmat/store-manager-entities:1.0",
        "name": "storemanagerentities",
        "resources": {
          "cpu": 0.5,
          "memory": "1Gi"
        }
      }
    ],
    "dapr": {
      "appId": "storemanagerentities",
      "appPort": 6002,
      "components": [
        {
          "metadata": [
            {
              "name": "accountName",
              "secretRef": "",
              "value": "storemanagerstorage"
            },
            {
              "name": "accountKey",
              "secretRef": "",
              "value": "q4dmK0iS/S2gDqmKQweNT/urMk5YuXQRqzZmHsytR90xTiNB1MWs2KbydpPw3N9t6lr9Y3cjBWgwAi3IVkGtmQ=="
            },
            {
              "name": "containerName",
              "secretRef": "",
              "value": "stateandactors"
            }
          ],
          "name": "statestore",
          "type": "state.azure.blobstorage",
          "version": "v1"
        },
        {
          "metadata": [
            {
              "name": "connectionString",
              "secretRef": "",
              "value": "Endpoint=sb://storemanager3596.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=pXO4Ex82/VtlCgWOme5Lh415BaTpYezkd2upQp21ylk="
            }
          ],
          "name": "pubsub",
          "type": "pubsub.azure.servicebus",
          "version": "v1"
        }
      ],
      "enabled": true
    },
    "revisionSuffix": "",
    "scale": {
      "maxReplicas": 1,
      "minReplicas": 1,
      "rules": null
    }
  },
  "type": "Microsoft.Web/containerApps"
}

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

{
  "configuration": {
    "activeRevisionsMode": "Multiple",
    "ingress": {
      "allowInsecure": false,
      "external": true,
      "fqdn": "node-hello.ambitiousdesert-ef67c030.canadacentral.azurecontainerapps.io",
      "targetPort": 8080,
      "traffic": [
        {
          "latestRevision": true,
          "revisionName": null,
          "weight": 100
        }
      ],
      "transport": "Auto"
    },
    "registries": null,
    "secrets": null
  },
  "id": "/subscriptions/0ba7fde9-7c4b-4693-96dd-65919b7692e8/resourceGroups/storemanager-rg/providers/Microsoft.Web/containerApps/node-hello",
  "kind": null,
  "kubeEnvironmentId": "/subscriptions/0ba7fde9-7c4b-4693-96dd-65919b7692e8/resourceGroups/storemanager-rg/providers/Microsoft.Web/kubeEnvironments/storemanager-env",
  "latestRevisionFqdn": "node-hello--lfg1i8s.ambitiousdesert-ef67c030.canadacentral.azurecontainerapps.io",
  "latestRevisionName": "node-hello--lfg1i8s",
  "location": "Canada Central",
  "name": "node-hello",
  "provisioningState": "Succeeded",
  "resourceGroup": "storemanager-rg",
  "tags": null,
  "template": {
    "containers": [
      {
        "args": null,
        "command": null,
        "env": null,
        "image": "khaledhikmat/node-hello-world-api:v1.0.3",
        "name": "node-hello",
        "resources": {
          "cpu": 0.5,
          "memory": "1Gi"
        }
      }
    ],
    "dapr": null,
    "revisionSuffix": "",
    "scale": {
      "maxReplicas": 1,
      "minReplicas": 1,
      "rules": null
    }
  },
  "type": "Microsoft.Web/containerApps"
}

Now this works - hitting the revision:
GET https://node-hello--lfg1i8s.ambitiousdesert-ef67c030.canadacentral.azurecontainerapps.io/health/liveness
GET https://node-hello--lfg1i8s.ambitiousdesert-ef67c030.canadacentral.azurecontainerapps.io/health/readiness
OR hitting the app:
https://node-hello.ambitiousdesert-ef67c030.canadacentral.azurecontainerapps.io/health/liveness

# Update Hello Node App
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