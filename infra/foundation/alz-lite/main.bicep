// ALZ-lite: the team's landing zone. Management groups, the shared services subscription's hub and
// Log Analytics workspace, and the core policies at mg-factory-corp.
// Deploy it at the Tenant Root management group with scripts/Deploy-AlzLite.ps1.
// Zones: none set. The firewall has no zone; pip-afw-hub is zone-redundant automatically.
targetScope = 'managementGroup'

@description('Azure region. Fallback: germanywestcentral.')
param location string = 'swedencentral'

@description('Prefix of the kit\'s management groups, so several kits can coexist.')
@minLength(2)
@maxLength(40)
param mgPrefix string = 'mg-factory'

@description('The team\'s shared services subscription.')
@minLength(36)
@maxLength(36)
param sharedSubscriptionId string

@description('Regions allowed at mg-factory-corp besides location and global, for example the fallback region.')
param additionalAllowedLocations array = []

@description('Microsoft Defender for Cloud on Foundational CSPM only: every paid plan off.')
param setDefenderFoundationalOnly bool = true

var platformMgName = '${mgPrefix}-platform'
var corpMgName = '${mgPrefix}-corp'

resource rootMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  scope: tenant()
  name: mgPrefix
  properties: {
    displayName: mgPrefix
    details: {
      parent: {
        id: managementGroup().id
      }
    }
  }
}

resource platformMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  scope: tenant()
  name: platformMgName
  properties: {
    displayName: platformMgName
    details: {
      parent: {
        id: rootMg.id
      }
    }
  }
}

resource corpMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  scope: tenant()
  name: corpMgName
  properties: {
    displayName: corpMgName
    details: {
      parent: {
        id: rootMg.id
      }
    }
  }
}

resource sharedPlacement 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = {
  parent: platformMg
  name: sharedSubscriptionId
}

module shared 'modules/shared-services.bicep' = {
  scope: subscription(sharedSubscriptionId)
  name: 'alz-lite-shared-services'
  params: {
    location: location
    setDefenderFoundationalOnly: setDefenderFoundationalOnly
  }
  dependsOn: [
    sharedPlacement
  ]
}

module policies 'modules/policies.bicep' = {
  scope: managementGroup(corpMgName)
  name: 'alz-lite-policies'
  params: {
    location: location
    allowedLocations: union([location, 'global'], additionalAllowedLocations)
    dnsZoneIds: shared.outputs.dnsZoneIds
    logAnalyticsWorkspaceId: shared.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    corpMg
  ]
}

// The DeployIfNotExists identities also need roles where the zones and the workspace live.
module zoneRoles 'modules/policy-roles.bicep' = {
  scope: resourceGroup(sharedSubscriptionId, 'rg-hub')
  name: 'alz-lite-policy-roles-hub'
  params: {
    assignments: policies.outputs.dnsIdentities
  }
}

module workspaceRoles 'modules/policy-roles.bicep' = {
  scope: resourceGroup(sharedSubscriptionId, 'rg-management')
  name: 'alz-lite-policy-roles-management'
  params: {
    assignments: policies.outputs.diagnosticsIdentities
  }
}

output rootManagementGroup string = rootMg.name
output platformManagementGroup string = platformMg.name
output corpManagementGroup string = corpMg.name
output hubVnetId string = shared.outputs.hubVnetId
output firewallPrivateIp string = shared.outputs.firewallPrivateIp
output firewallPolicyId string = shared.outputs.firewallPolicyId
output dnsZoneResourceGroupId string = shared.outputs.dnsZoneResourceGroupId
output logAnalyticsWorkspaceId string = shared.outputs.logAnalyticsWorkspaceId
output sqlMiIdentityId string = shared.outputs.sqlMiIdentityId
