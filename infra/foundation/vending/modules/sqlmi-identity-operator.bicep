// Managed Identity Operator for the member on id-sqlmi-directory, so the archetype they deploy can
// attach it to their SQL Managed Instance. Members also get Reader on the shared services subscription (hub-reader.bicep).
targetScope = 'resourceGroup'

param memberPrincipalId string

var managedIdentityOperatorRole = 'f1a07417-d97a-45cb-824c-7a7467783830'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: 'id-sqlmi-directory'
}

resource memberOperator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: identity
  name: guid(identity.id, memberPrincipalId, managedIdentityOperatorRole)
  properties: {
    principalId: memberPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', managedIdentityOperatorRole)
  }
}
