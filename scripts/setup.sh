#!/bin/bash

RESOURCE_GROUP=$1
APP_ID=$2
OBJECT_ID=$3
SUBSCRIPTION_NAME=$4

RESOURCE_GROUP="ti-horde-storage-mrg-0-1-5"
APP_ID="4a85b31a-11de-4212-859d-cd4d03fe8bf8"
OBJECT_ID="b166ec03-a8a1-4617-b5b2-f87ac4132c4e"
SUBSCRIPTION_NAME="Azure-Gaming-Horde-Storage"


az account set -s $SUBSCRIPTION_NAME
az account show

function setup_kv(){
    SUBSCRIPTION_ID=$(az account show --query "id" --output tsv)
    MY_ID=$(az ad signed-in-user show --query "id" --output tsv)
    KEY_VAULTS=$(az keyvault list -g "$RESOURCE_GROUP" --query [].[name] --output tsv)

    for KEYVAULT_NAME in $KEY_VAULTS; do
        echo "##[section] Set values for Resource Group: $RESOURCE_GROUP and Key Vault: $KEYVAULT_NAME"
        ADMIN_ROLE="Key Vault Administrator"
        SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME"
        echo "##[debug] Grant Key Vault access to self, SCOPE: $SCOPE"
        az role assignment create \
            --role "$ADMIN_ROLE" \
            --assignee "$MY_ID" \
            --scope $SCOPE
            > /dev/null || break

        echo "##[debug] Grant Key Vault access to Service Principal, SCOPE: $SCOPE"
        az role assignment create \
            --role "$ADMIN_ROLE" \
            --assignee "$APP_ID" \
            --scope $SCOPE \
            > /dev/null || break

        SECRET=$(
        az ad app credential reset \
            --display-name "unreal-cloud-ddc" \
            --id "$APP_ID" \
            --append \
            --only-show-errors \
            --query "password" \
            --output tsv \
            || break
        )

        echo "##[debug] Create secrets in Key Vault"
        az keyvault secret set \
            --vault-name "$KEYVAULT_NAME" \
            --name "horde-client-app-secret" \
            --value "$SECRET" \
            > /dev/null || break

        az keyvault secret set \
            --vault-name "$KEYVAULT_NAME" \
            --name "build-app-secret" \
            --value "$SECRET" \
            > /dev/null || break

    done

    echo "##[debug] Complete"
}

function setup_aks(){
    CLUSTER_NAMES=$(az aks list -g "$RESOURCE_GROUP" --query [].[name] --output tsv)

    for CLUSTER_NAME in $CLUSTER_NAMES; do
        echo '##[section] Horde Storage - enable OIDC issuer'

        az feature register \
            --only-show-errors \
            --name EnableOIDCIssuerPreview \
            --namespace Microsoft.ContainerService \
            > /dev/null || break

        az provider register \
            --only-show-errors \
            --namespace Microsoft.ContainerService \
            > /dev/null || break

        echo '##[command] az extension add --name aks-preview && az extension update --name aks-preview'
        az extension add \
            --only-show-errors \
            --name aks-preview \
        && az extension update \
            --only-show-errors \
            --name aks-preview \
            > /dev/null || break

        echo "##[command] az aks update -n $CLUSTER_NAME -g $RESOURCE_GROUP --enable-oidc-issuer"
        az aks update \
            --only-show-errors \
            -n "$CLUSTER_NAME" \
            -g "$RESOURCE_GROUP" \
            --enable-oidc-issuer \
            > /dev/null || break

        echo "##[command] ISSUER_URL=$(az aks show -n "$CLUSTER_NAME" -g "$RESOURCE_GROUP" --query 'oidcIssuerProfile.issuerUrl' -otsv)"
        ISSUER_URL=$(
        az aks show \
            --only-show-errors \
            -n "$CLUSTER_NAME" \
            -g "$RESOURCE_GROUP" \
            --query "oidcIssuerProfile.issuerUrl" -otsv
        )

        echo "##[debug] Create or Update Federated Identity"
        echo '{"name":"'"$CLUSTER_NAME"'", "issuer":"'"$ISSUER_URL"'", "subject":"system:serviceaccount:horde-tests:workload-identity-sa", "description":"For use by Horde Storage app on pipeline test cluster ", "audiences":["api://AzureADTokenExchange"] }' > parameters.json

        echo "##[command] az ad app federated-credential create --id $OBJECT_ID --parameters parameters.json || az ad app federated-credential update"
        az ad app federated-credential update \
            --id "$OBJECT_ID" \
            --federated-credential-id "$CLUSTER_NAME" \
            --parameters parameters.json \
            > /dev/null 2>&1 \
        || az ad app federated-credential create \
            --id "$OBJECT_ID" \
            --parameters parameters.json
    done
}

setup_kv
setup_aks
