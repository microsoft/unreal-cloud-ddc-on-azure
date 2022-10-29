echo "Subscription Name?   (Type and press enter to continue)" && read -r SUBSCRIPTION_NAME
echo "Resource Group Name? (Type and press enter to continue)" && read -r RG
echo "App Name?            (Type and press enter to continue)" && read -r APP_NAME
echo "Traffic Manager?     (Type and press enter to continue)" && read -r TM_NAME

az account set -s "$SUBSCRIPTION_NAME"

managedResourceGroupId=$(az managedapp show --name $APP_NAME --resource-group $RG --query managedResourceGroupId --output tsv)
resourceGroup=$(echo ${managedResourceGroupId##*/})
nodeResourceGroups=$(az aks list --resource-group $resourceGroup --query [].[nodeResourceGroup] --output tsv)

for nodeResourceGroup in $nodeResourceGroups; do
    ipName=$(az network public-ip list --resource-group $nodeResourceGroup --query "[?contains(name,'kub')].[name]" --output tsv)
    ipID=$(az network public-ip list --resource-group $nodeResourceGroup --query "[?contains(name,'kub')].[id]" --output tsv)
    location=$(az network public-ip list --resource-group $nodeResourceGroup --query "[?contains(name,'kub')].[location]" --output tsv)
    az network public-ip update \
        --name $ipName \
        --dns-name $ipName \
        --resource-group $nodeResourceGroup
    
    az network traffic-manager endpoint create \
        --resource-group $RG \
        --profile-name $TM_NAME \
        -n $location \
        --type azureEndpoints \
        --target-resource-id $ipID \
        --endpoint-status enabled
done

account=$(az cosmosdb list --resource-group $resourceGroup --query [].[name] --output tsv)

declare -A tables=(
    [blob_index]="32000"
    [objects]="4000"
    [buckets]="8000"
    [content_id]="4000"
)

keySpace='jupiter'

for table in ${!tables[@]}; do
    az cosmosdb cassandra table throughput update \
        --account-name $account \
        --resource-group $resourceGroup \
        --keyspace-name $keySpace \
        --name $table \
        --throughput ${tables[${table}]} \
    && az cosmosdb cassandra table throughput migrate \
        --account-name $account \
        --resource-group $resourceGroup \
        --keyspace-name $keySpace \
        --name $table \
        --throughput-type "autoscale"
done

declare -A REGION_TABLES=( \
    [replication_log]="4000" \
    [replication_namespace]="4000" \
)

KEY_VAULTS=$(az keyvault list -g "$resourceGroup" --query [].[name] --output tsv)
for table in ${!REGION_TABLES[@]}; do
    for KEY_VAULT in $KEY_VAULTS; do
        LOCATION=$(echo "$KEY_VAULT" | awk -F'-' '{print $1}')
        az cosmosdb cassandra table throughput update \
            --account-name $account \
            --resource-group $resourceGroup \
            --keyspace-name "${keySpace}_local_${LOCATION}" \
            --name $table \
            --throughput ${REGION_TABLES[${table}]} \
        && az cosmosdb cassandra table throughput migrate \
            --account-name $account \
            --resource-group $resourceGroup \
            --keyspace-name "${keySpace}_local_${LOCATION}" \
            --name $table \
            --throughput-type "autoscale"
    done
done
