// Reader for the member on the shared services subscription, so they can read the hub with their own
// sign-in: Test-Connectivity.ps1 (afw-hub, the private DNS zone links in rg-hub) and the archetype's
// preflight (the hub VNet, the firewall policy and its rules, log-management and id-sqlmi-directory in
// rg-management). The preflight lists firewall policies across the subscription, which a Reader
// assignment on the two resource groups doesn't cover. The subscription holds only the team's hub.
targetScope = 'subscription'

param memberPrincipalId string

var readerRole = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource memberReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, memberPrincipalId, readerRole)
  properties: {
    principalId: memberPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRole)
  }
}
