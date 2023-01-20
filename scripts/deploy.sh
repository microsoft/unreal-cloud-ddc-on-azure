#!/bin/bash
# The following variables must be set before running this script.
#
# PARAMETERS_FILE: Parmaeters file used for deployment
PARAMETERS_FILE=$1

LOCATION=$(jq -r '.parameters.location.value' "$PARAMETERS_FILE")
RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' "$PARAMETERS_FILE")

az account set -s "Azure-Gaming-Canary"

echo '##[section]Horde Storage - Deploy Bicep Template'
az bicep install --version v0.11.1

az group create \
    --name "$RESOURCE_GROUP"\
    --location "$LOCATION"

az deployment group create \
    --name "$RESOURCE_GROUP" \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters "$PARAMETERS_FILE" \
    --parameters servicePrincipalClientID=$SERVICE_SP \
    --parameters workerServicePrincipalClientID=$WORKER_SP \
    --parameters workerServicePrincipalSecret=$AAD_SECRET \
    || exit 1
