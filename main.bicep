@description('Deployment Location')
param location string = resourceGroup().location

@description('Secondary Deployment Locations')
param secondaryLocations array = []

@allowed([
  'new'
  'existing'
])
param newOrExistingKubernetes string = 'new'
param name string = 'horde-storage-${uniqueString(resourceGroup().id)}'
param agentPoolCount int = 3
param agentPoolName string = 'k8agent'
param vmSize string = 'Standard_L16s_v2'
param hostname string = 'deploy1.horde-storage.gaming.azure.com'

@description('Unknown, Self, or {IssuerName} for certificate signing')
param certificateIssuer string = 'Self'

@description('Certificate Issuer Provider')
param issuerProvider string = ''

@description('Running this template requires roleAssignment permission on the Resource Group, which require an Owner role. Set this to false to deploy some of the resources')
param assignRole bool = true

@allowed([
  'new'
  'existing'
])
param newOrExistingStorageAccount string = 'new'
param storageAccountName string = 'hordestore${uniqueString(resourceGroup().id, subscription().subscriptionId)}'

@allowed([
  'new'
  'existing'
])
param newOrExistingKeyVault string = 'new'
param keyVaultName string = take('hordeKeyVault${uniqueString(resourceGroup().id, subscription().subscriptionId, location)}', 24)

@allowed([
  'new'
  'existing'
])
param newOrExistingPublicIp string = 'new'
param publicIpName string = 'hordePublicIP${uniqueString(resourceGroup().id, subscription().subscriptionId)}'

@allowed([
  'new'
  'existing'
])
param newOrExistingTrafficManager string = 'new'
param trafficManagerName string = 'hordePublicIP${uniqueString(resourceGroup().id, subscription().subscriptionId)}'
@description('Relative DNS name for the traffic manager profile, must be globally unique.')
param trafficManagerDnsName string = 'tmp-${uniqueString(resourceGroup().id, subscription().id)}'

@allowed([
  'new'
  'existing'
])
param newOrExistingCosmosDB string = 'new'
param cosmosDBName string = 'hordeDB-${uniqueString(resourceGroup().id, subscription().subscriptionId)}'

param servicePrincipalObjectID string = ''

param servicePrincipalClientID string = ''

@description('Name of Certificate (Default certificate is self-signed)')
param certificateName string = 'horde-storage-cert'

@description('Set to true to agree to the terms and conditions of the Epic Games EULA found here: https://store.epicgames.com/en-US/eula')
param unityEULA bool = false

param managedResourceGroupName string = 'mrg'

var managedResourceGroupId = '${subscription().id}/resourceGroups/${resourceGroup().name}-${managedResourceGroupName}'

resource hordeStorage 'Microsoft.Solutions/applications@2017-09-01' = {
  location: location
  kind: 'MarketPlace'
  name: name
  plan: {
    name: 'preview'
    product: 'horde-storage-preview'
    publisher: 'microsoft-azure-gaming'
    version: '0.0.22'
  }
  properties: {
    managedResourceGroupId: managedResourceGroupId
    parameters: {
      location: {
        value: location
      }
      secondaryLocations: {
        value: secondaryLocations
      }
      newOrExistingKubernetes: {
        value: newOrExistingKubernetes
      }
      name: {
        value: name
      }
      agentPoolCount: {
        value: agentPoolCount
      }
      agentPoolName: {
        value: agentPoolName
      }
      vmSize: {
        value: vmSize
      }
      hostname: {
        value: hostname
      }
      certificateIssuer: {
        value: certificateIssuer
      }
      issuerProvider: {
        value: issuerProvider
      }
      assignRole: {
        value: assignRole
      }
      newOrExistingStorageAccount: {
        value: newOrExistingStorageAccount
      }
      storageAccountName: {
        value: storageAccountName
      }
      newOrExistingKeyVault: {
        value: newOrExistingKeyVault
      }
      keyVaultName: {
        value: keyVaultName
      }
      newOrExistingPublicIp: {
        value: newOrExistingPublicIp
      }
      publicIpName: {
        value: publicIpName
      }
      newOrExistingTrafficManager: {
        value: newOrExistingTrafficManager
      }
      trafficManagerName: {
        value: trafficManagerName
      }
      trafficManagerDnsName: {
        value: trafficManagerDnsName
      }
      newOrExistingCosmosDB: {
        value: newOrExistingCosmosDB
      }
      cosmosDBName: {
        value: cosmosDBName
      }
      servicePrincipalObjectID: {
        value: servicePrincipalObjectID
      }
      servicePrincipalClientID: {
        value: servicePrincipalClientID
      }
      certificateName: {
        value: certificateName
      }
      unityEULA: {
        value: unityEULA
      }      
    }
    jitAccessPolicy: null
  }
}
