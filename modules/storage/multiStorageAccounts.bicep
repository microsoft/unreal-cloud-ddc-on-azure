@description('Deployment Location')
param location string

@description('Secondary Deployment Locations')
param secondaryLocations array = []

@allowed([ 'Standard', 'Premium' ])
@description('Storage Account Tier. Standard or Premium.')
param storageAccountTier string = 'Standard'

@description('Storage Account Type. Use Zonal Redundant Storage when able.')
param storageAccountType string

param storageAccountName string

module storageAccount 'storageAccounts.bicep' = [for location in union([ location ], secondaryLocations): {
  name: 'storageAccount-${uniqueString(location, resourceGroup().id, deployment().name)}'
  params: {
    location: location
    name: storageAccountName
    storageAccountTier: storageAccountTier
    storageAccountType: storageAccountType
  }
}]

output storageConnectionStrings array = [for (location, index) in union([ location ], secondaryLocations): storageAccount[index].outputs.blobStorageConnectionString]

