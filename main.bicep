@description('Deployment Location')
param location string = resourceGroup().location

param resourceGroupName string = resourceGroup().name

@description('Secondary Deployment Locations')
param secondaryLocations array = []

@allowed([ 'new', 'existing' ])
param newOrExistingKubernetes string = 'new'
param prefix string = uniqueString(location, resourceGroup().id, deployment().name)
param name string = 'ddc-storage'
param agentPoolCount int = 2
param agentPoolName string = 'k8agent'
param vmSize string = 'Standard_L8s_v3'
param hostname string = '${prefix}.ddc-storage.gaming.azure.com'
param isZoneRedundant bool = false

@description('Running this template requires roleAssignment permission on the Resource Group, which require an Owner role. Set this to false to deploy some of the resources')
param assignRole bool = true

@allowed([ 'Standard', 'Premium' ])
@description('Storage Account Tier. Standard or Premium.')
param storageAccountTier string = 'Standard'

@description('Storage Account Type. Use Zonal Redundant Storage when able.')
param storageAccountType string = isZoneRedundant ? '${storageAccountTier}_ZRS' : '${storageAccountTier}_LRS'

@allowed([ 'new', 'existing' ])
param newOrExistingStorageAccount string = 'new'
param storageAccountName string = 'ddcstore${uniqueString(resourceGroup().id, subscription().subscriptionId, location, storageAccountType, newOrExistingStorageAccount == 'new' ? publishers[publisher].version : '')}'

@allowed([ 'new', 'existing' ])
param newOrExistingKeyVault string = 'new'
param keyVaultName string = take('${uniqueString(resourceGroup().id, subscription().subscriptionId, publishers[publisher].version, location)}', 24)

@allowed([ 'new', 'existing' ])
param newOrExistingPublicIp string = 'new'
param publicIpName string = 'ddcPublicIP${uniqueString(resourceGroup().id, subscription().subscriptionId, publishers[publisher].version, location)}'

@allowed([ 'new', 'existing' ])
param newOrExistingTrafficManager string = 'new'
param trafficManagerName string = 'ddcPublicIP${uniqueString(resourceGroup().id, subscription().subscriptionId, publishers[publisher].version, location)}'

@description('Relative DNS name for the traffic manager profile, must be globally unique.')
param trafficManagerDnsName string = 'tmp-${uniqueString(resourceGroup().id, subscription().id)}'

@allowed([ 'new', 'existing' ])
param newOrExistingCosmosDB string = 'new'
param cosmosDBName string = 'ddcDB-${uniqueString(resourceGroup().id, subscription().subscriptionId, location)}'

param servicePrincipalClientID string = ''

param workerServicePrincipalClientID string = servicePrincipalClientID

@secure()
param workerServicePrincipalSecret string = ''

@description('Enable to configure certificate. Default: true')
param enableCert bool = true

@description('Name of Certificate (Default certificate is self-signed)')
param certificateName string = 'unreal-cloud-ddc-cert'

@description('Set to true to agree to the terms and conditions of the Epic Games EULA found here: https://store.epicgames.com/en-US/eula')
param epicEULA bool = false

param managedResourceGroupName string = 'mrg'

param seperateResources = true

@allowed([ 'dev', 'prod' ])
param publisher string = 'prod'
param publishers object = {
  dev: {
    name: 'preview'
    product: 'unreal-cloud-ddc-temp'
    publisher: 'microsoftcorporation1590077852919'
    version: '0.0.0'
  }
  prod: {
    name: 'preview'
    product: 'unreal-cloud-ddc-preview'
    publisher: 'microsoft-azure-gaming'
    version: '0.1.32'
  }
}

var certificateIssuer = 'Subscription-Issuer'
var issuerProvider = 'OneCertV2-PublicCA'
var managedResourceGroupName = ${resourceGroup().name}-${managedResourceGroupName}-${replace(publishers[publisher].version,'.','-')}
var managedResourceGroupId = '${subscription().id}/resourceGroups/${managedResourceGroupName}'
var appName = '${prefix}${name}-${replace(publishers[publisher].version,'.','-')}'

module cassandra 'modules/documentDB/databaseAccounts.bicep' = if(seperateResources) {
  name: 'cassandra-${uniqueString(location, resourceGroup().name)}'
  params: {
    location: location
    secondaryLocations: secondaryLocations
    newOrExisting: newOrExistingCosmosDB
    name: 'ddc${cosmosDBName}'
  }
}

module storageAccount 'modules/storage/storageAccounts.bicep' = [for location in union([ location ], secondaryLocations): if(seperateResources) {
  name: 'storageAccount-${uniqueString(location, resourceGroup().id, deployment().name)}'
  params: {
    location: location
    name: take('${take(location, 8)}${storageAccountName}',24)
    storageAccountTier: storageAccountTier
    storageAccountType: storageAccountType
  }
}]

resource ddcStorage 'Microsoft.Solutions/applications@2017-09-01' = {
  location: location
  kind: 'MarketPlace'
  name: appName
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
        value: seperateResources ? 'existing' : newOrExistingStorageAccount
      }
      storageAccountName: {
        value: storageAccountName
      }
      storageAccountResourceGroupName: {
        value: seperateResources ? resourceGroupName : managedResourceGroupName
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
        value: seperateResources ? 'existing' : newOrExistingCosmosDB
      }
      cosmosDBName: {
        value: 'ddc${cosmosDBName}'
      }
      cosmosDBRG: {
        value: seperateResources ? resourceGroupName : managedResourceGroupName
      }
      servicePrincipalClientID: {
        value: servicePrincipalClientID
      }
      workerServicePrincipalClientID: {
        value: workerServicePrincipalClientID
      }
      workerServicePrincipalSecret: {
        value: workerServicePrincipalSecret
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
      enableCert: {
        value: enableCert
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

output prefix string = prefix
output appName string = appName
