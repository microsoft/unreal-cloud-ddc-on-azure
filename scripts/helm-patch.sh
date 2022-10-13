#!/bin/bash

STUDIO="ti"
LOCATION="westus"
VERSION="0-1-5"

MANAGED_RESOURCE_GROUP="$STUDIO-horde-storage-mrg-$VERSION"
CLUSTER_NAME="horde-storage-${LOCATION:0:8}"
PARAMETERS_FILE="helm/values-$STUDIO-$LOCATION.yaml"

az aks install-cli

az aks get-credentials \
    --resource-group $MANAGED_RESOURCE_GROUP \
    --name $CLUSTER_NAME


function setup_secret_store(){
    HELM_REPO='csi-secrets-store-provider-azure'
    HELM_REPO_URL='https://azure.github.io/secrets-store-csi-driver-provider-azure/charts'
    HELM_NAME='csi'
    HELM_CHART='csi-secrets-store-provider-azure/csi-secrets-store-provider-azure'
    HELM_NAMESPACE='kube-system'
    PARAMETERS_FILE='helm/secrets-store-values.yaml'

    helm repo add $HELM_REPO $HELM_REPO_URL && helm repo update
    helm upgrade $HELM_NAME $HELM_CHART \
        --install \
        --create-namespace --namespace $HELM_NAMESPACE \
        --values $PARAMETERS_FILE
}

function setup_ddc(){
    PARAMETERS_FILE="helm/values-$STUDIO-$LOCATION.yaml"

    helm upgrade myhordetest helm \
        --namespace horde-tests \
        --values $PARAMETERS_FILE \
        --set horde-storage.podForceRestart=true \
        --create-namespace \
        --install
}

setup_secret_store
setup_ddc
