#!/bin/bash
# The following variables must be set before running this script.
#
# SUBSCRIPTION_ID: Azure Subscription ID
# LOCATION: Azure Region for deployment
# RESOURCE_GROUP: Resourece Group Name
SUBSCRIPTION_ID=$1
LOCATION=$2
RESOURCE_GROUP=$3
PARAMETERS=$4

echo '##[section]Horde Storage - Deploy Bicep Template'
az bicep install --version v0.10.61

az group create \
    --name "$RESOURCE_GROUP"\
    --location "$LOCATION" \
    --subscription "$SUBSCRIPTION_ID"

az deployment group create \
    --name "$RESOURCE_GROUP" \
    --subscription "$SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters PARAMETERS \
    || exit 1
