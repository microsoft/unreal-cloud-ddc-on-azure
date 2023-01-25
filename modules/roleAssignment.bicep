targetScope = 'subscription'

@description('The principal to assign the role to')
param principalId string

// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#all
var rbacRolesNeeded = [
  '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
  '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9' // User Access Administrator
]

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefId in rbacRolesNeeded: {
  name: guid(roleDefId, principalId)
  properties: {
    roleDefinitionId: roleDefId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]
