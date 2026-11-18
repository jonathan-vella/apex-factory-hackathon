// Reader for the member on the kit's root management group (<mgPrefix>), inherited by <mgPrefix>-corp
// and <mgPrefix>-platform, so live governance discovery in /apex-adapt-archetype can resolve policy
// assignments and custom definitions at kit management-group scopes without granting Tenant Root access.
targetScope = 'managementGroup'

param memberPrincipalId string
param description string = 'Created by Deploy-Vending.ps1 (Partner Modernization Factory)'

var readerRole = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource memberMgReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, memberPrincipalId, readerRole)
  properties: {
    principalId: memberPrincipalId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', readerRole)
    description: description
  }
}
