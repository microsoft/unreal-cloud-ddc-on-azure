#!/bin/bash

STUDIO="ti"
LOCATION="westus"
VERSION="0-1-5"
STATIC_IP='20.225.20.67'

TENANT_ID='72f988bf-86f1-41af-91ab-2d7cd011db47'
MANAGED_RESOURCE_GROUP="$STUDIO-horde-storage-mrg-$VERSION"
CLUSTER_NAME="horde-storage-${LOCATION:0:8}"
PARAMETERS_FILE="helm/values-$STUDIO-$LOCATION.yaml"

IP_RG="MC_${MANAGED_RESOURCE_GROUP}_${CLUSTER_NAME}_${LOCATION}"

az aks install-cli

az aks get-credentials \
    --resource-group $MANAGED_RESOURCE_GROUP \
    --name $CLUSTER_NAME

function setup_nginx(){
    HELM_REPO='ingress-nginx'
    HELM_REPO_URL='https://kubernetes.github.io/ingress-nginx'
    HELM_NAME='ingress-nginx'
    HELM_CHART='ingress-nginx/ingress-nginx'
    HELM_NAMESPACE='ingress-basic'
    VERSION='4.1.3'
    PARAMETERS_FILE='helm/nginx-values.yaml'

    helm repo add $HELM_REPO $HELM_REPO_URL && helm repo update
    helm upgrade $HELM_NAME $HELM_CHART \
        --install \
        --create-namespace --namespace $HELM_NAMESPACE \
        --version $VERSION \
        --values $PARAMETERS_FILE \
        --set ingress-nginx.controller.service.loadBalancerIP=$STATIC_IP,ingress-nginx.controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group=$IP_RG
}

function setup_workload_id(){
    HELM_REPO='azure-workload-identity'
    HELM_REPO_URL='https://azure.github.io/azure-workload-identity/charts'
    HELM_NAME='workload-identity-webhook'
    HELM_CHART='azure-workload-identity/workload-identity-webhook'
    HELM_NAMESPACE='azure-workload-identity-system'
    PARAMETERS_FILE='helm/workload-values.yaml'

    helm repo add $HELM_REPO $HELM_REPO_URL && helm repo update
    helm upgrade $HELM_NAME $HELM_CHART \
        --install \
        --create-namespace \
        --namespace $HELM_NAMESPACE \
        --values $PARAMETERS_FILE
}

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

# setup_workload_id
# setup_nginx
setup_secret_store
setup_ddc
