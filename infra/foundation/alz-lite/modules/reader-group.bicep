targetScope = 'managementGroup'

param readerGroupId string

var readerRole = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource readerGroup 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(toLower(managementGroup().id), toLower(readerGroupId), readerRole)
  properties: {
    principalId: readerGroupId
    principalType: 'Group'
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', readerRole)
    description: 'Created by Deploy-AlzLite.ps1 (Partner Modernization Factory): reader group'
  }
}
