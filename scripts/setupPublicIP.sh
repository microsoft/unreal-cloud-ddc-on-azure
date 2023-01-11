#!/bin/bash
# The following variables must be set before running this script.
#
# PARAMETERS_FILE: Parmaeters file used for deployment
PARAMETERS_FILE=$1

RG=$(jq -r '.parameters.resourceGroupName.value' "$PARAMETERS_FILE")

managedResourceGroupIds=$(az managedapp list --resource-group $RG --query [].managedResourceGroupId --output tsv)

for managedResourceGroupId in $managedResourceGroupIds; do
    resourceGroup=$(echo ${managedResourceGroupId##*/})
    nodeResourceGroups=$(az aks list --resource-group $resourceGroup --query [].[nodeResourceGroup] --output tsv)

    for nodeResourceGroup in $nodeResourceGroups; do
        ipName=$(az network public-ip list --resource-group $nodeResourceGroup --query "[?contains(name,'kub')].[name]" --output tsv)
        ipID=$(az network public-ip list --resource-group $nodeResourceGroup --query "[?contains(name,'kub')].[id]" --output tsv)
        location=$(az network public-ip list --resource-group $nodeResourceGroup --query "[?contains(name,'kub')].[location]" --output tsv)

        echo ipName: $ipName
        echo ipID: $ipID
        echo location: $location

        az network public-ip update \
            --name $ipName \
            --dns-name $ipName \
            --resource-group $nodeResourceGroup
    done
done
