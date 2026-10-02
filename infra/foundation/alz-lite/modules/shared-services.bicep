// The shared services subscription: rg-management with log-management, rg-hub with the hub, and
// Defender for Cloud on Foundational CSPM only.
targetScope = 'subscription'

param location string
param setDefenderFoundationalOnly bool

resource managementRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-management'
  location: location
}

resource hubRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-hub'
  location: location
}

module workspace 'workspace.bicep' = {
  scope: managementRg
  name: 'alz-lite-workspace'
  params: {
    location: location
  }
}

module hub 'hub.bicep' = {
  scope: hubRg
  name: 'alz-lite-hub'
  params: {
    location: location
    logAnalyticsWorkspaceId: workspace.outputs.workspaceId
  }
}

module defender '../../modules/defender-foundational.bicep' = if (setDefenderFoundationalOnly) {
  name: 'alz-lite-defender'
}

output hubVnetId string = hub.outputs.vnetId
output firewallPrivateIp string = hub.outputs.firewallPrivateIp
output firewallPolicyId string = hub.outputs.firewallPolicyId
output dnsZoneIds object = hub.outputs.dnsZoneIds
output dnsZoneResourceGroupId string = hubRg.id
output logAnalyticsWorkspaceId string = workspace.outputs.workspaceId
