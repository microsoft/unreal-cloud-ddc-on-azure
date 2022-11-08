@description('Deployment Location')
param location string = resourceGroup().location

@description('Secondary Deployment Locations')
param secondaryLocations array = []

@allowed([
  'new'
  'existing'
])
param newOrExistingKubernetes string = 'new'
param prefix string = uniqueString(location, resourceGroup().id, deployment().name)
param name string = 'horde-storage'
param agentPoolCount int = 3
param agentPoolName string = 'k8agent'
param vmSize string = 'Standard_L8s_v3'
param hostname string = 'deploy1.horde-storage.gaming.azure.com'
param isZoneRedundant bool = false

@description('Running this template requires roleAssignment permission on the Resource Group, which require an Owner role. Set this to false to deploy some of the resources')
param assignRole bool = true

@allowed([
  'new'
  'existing'
])
param newOrExistingStorageAccount string = 'new'
param storageAccountName string = 'hordestore${uniqueString(resourceGroup().id, subscription().subscriptionId, publishers[publisher].version, location)}'

@allowed([
  'new'
  'existing'
])
param newOrExistingKeyVault string = 'new'
param keyVaultName string = take('${uniqueString(resourceGroup().id, subscription().subscriptionId, publishers[publisher].version, location)}', 24)

@allowed([
  'new'
  'existing'
])
param newOrExistingPublicIp string = 'new'
param publicIpName string = 'hordePublicIP${uniqueString(resourceGroup().id, subscription().subscriptionId, publishers[publisher].version, location)}'

@allowed([
  'new'
  'existing'
])
param newOrExistingTrafficManager string = 'new'
param trafficManagerName string = 'hordePublicIP${uniqueString(resourceGroup().id, subscription().subscriptionId, publishers[publisher].version, location)}'
@description('Relative DNS name for the traffic manager profile, must be globally unique.')
param trafficManagerDnsName string = 'tmp-${uniqueString(resourceGroup().id, subscription().id)}'

@allowed([
  'new'
  'existing'
])
param newOrExistingCosmosDB string = 'new'
param cosmosDBName string = 'hordeDB-${uniqueString(resourceGroup().id, subscription().subscriptionId, publishers[publisher].version, location)}'

param servicePrincipalClientID string = ''

@secure()
param servicePrincipalSecret string = ''

@description('Name of Certificate (Default certificate is self-signed)')
param certificateName string = 'unreal-cloud-ddc-cert'

@description('Set to true to agree to the terms and conditions of the Epic Games EULA found here: https://store.epicgames.com/en-US/eula')
param epicEULA bool = false

param managedResourceGroupName string = 'mrg'

@allowed([
  'dev'
  'prod'
])
param publisher string = 'prod'
param publishers object = {
  dev: {
    name: 'preview'
    product: 'horde-storage-preview'
    publisher: 'microsoftcorporation1590077852919'
    version: '1.0.730'
  }
  prod: {
    name: 'preview'
    product: 'horde-storage-preview'
    publisher: 'microsoft-azure-gaming'
    version: '0.1.19'
  }
}

var certificateIssuer = 'Subscription-Issuer'
var issuerProvider = 'OneCertV2-PublicCA'
var managedResourceGroupId = '${subscription().id}/resourceGroups/${resourceGroup().name}-${managedResourceGroupName}-${replace(publishers[publisher].version,'.','-')}'

resource hordeStorage 'Microsoft.Solutions/applications@2017-09-01' = {
  location: location
  kind: 'MarketPlace'
  name: '${prefix}${name}-${replace(publishers[publisher].version,'.','-')}'
  plan: publishers[publisher]
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
      aksName: {
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
        value: '${trafficManagerDnsName}-${replace(publishers[publisher].version,'.','-')}'
      }
      newOrExistingCosmosDB: {
        value: newOrExistingCosmosDB
      }
      cosmosDBName: {
        value: cosmosDBName
      }
      servicePrincipalClientID: {
        value: servicePrincipalClientID
      }
      servicePrincipalSecret: {
        value: servicePrincipalSecret
      }
      certificateName: {
        value: certificateName
      }
      epicEULA: {
        value: epicEULA
      }
      isZoneRedundant: {
        value: isZoneRedundant
      }
    }
    jitAccessPolicy: null
  }
}

module trafficManager 'modules/network/trafficManagerProfiles.bicep' = {
  name: 'trafficManager-${uniqueString(location, resourceGroup().id, deployment().name)}'
  params: {
    name: '${prefix}ddc'
    newOrExisting: 'new'
    trafficManagerDnsName: '${prefix}preview.unreal-cloud-ddc'
  }
}
