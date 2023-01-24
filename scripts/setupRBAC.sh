#!/bin/bash
# The following variables must be set before running this script.
#
# PARAMETERS_FILE: Parmaeters file used for deployment
PARAMETERS_FILE=$1

# SUBSCRIPTION_ID=$(az account list --query "[].{id:id}" --output tsv)

RG=$(jq -r '.parameters.resourceGroupName.value' "$PARAMETERS_FILE")

managedResourceGroupIds=$(az managedapp list --resource-group $RG --query [].managedResourceGroupId --output tsv)

for managedResourceGroupId in $managedResourceGroupIds; do
    resourceGroup=$(echo ${managedResourceGroupId##*/})

    aksClusters=$(az aks list --resource-group $resourceGroup --query [].[name] --output tsv)
    locations=$(az aks list --resource-group $resourceGroup --query [].[location] --output tsv)
    keyVaults=$(az keyvault list --resource-group $resourceGroup --query [].[name] --output tsv)

    for location in $locations; do
        # Key Vault
        assignee=$(az ad user show --id "id-ddc-storage-$location" --query "id" --output tsv)
        
        az role assignment create --assignee "$assignee" \
            --role "{roleNameOrId}" \
            --scope "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{providerName}/{resourceType}/{resourceSubType}/{resourceName}"

        # AKS
        # az ad sp list --all --filter "servicePrincipalType eq 'ManagedIdentity'"
        assignee=$(az ad user show --id "id-AksRunCommandProxy" --query "id" --output tsv)
        az role assignment create --assignee "$assignee" \
            --role "{roleNameOrId}" \
            --scope "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{providerName}/{resourceType}/{resourceSubType}/{resourceName}"
    done
done
