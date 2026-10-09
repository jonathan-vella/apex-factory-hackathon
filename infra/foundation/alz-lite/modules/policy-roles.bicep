// Roles for the ALZ-lite DeployIfNotExists identities on a resource group in the shared services
// subscription: rg-hub (the zones) or rg-management (the workspace).
param assignments array

resource roles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for item in assignments: {
    name: guid(resourceGroup().id, item.name, item.roleDefinitionId)
    properties: {
      principalId: item.principalId
      principalType: 'ServicePrincipal'
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', item.roleDefinitionId)
    }
  }
]
