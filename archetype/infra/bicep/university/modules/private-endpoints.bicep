@description('Uniqueness suffix shared by every name.')
param suffix string

@description('Fixed project segment used in names.')
param projectName string

@description('Azure region of the private endpoints (also the diagnostic setting location).')
param location string

@description('Resource tags.')
param tags object

@description('Resource ID of the vended private-endpoint subnet (snet-pe).')
param subnetId string

@description('Resource ID of the central log-management workspace.')
param logAnalyticsWorkspaceId string

@description('Resource ID of the container registry.')
param registryResourceId string

@description('Resource ID of the storage account.')
param storageResourceId string

@description('Resource ID of the Service Bus namespace.')
param serviceBusResourceId string

@description('Resource ID of the Key Vault.')
param keyVaultResourceId string

var endpoints = [
  {
    key: 'acr'
    targetId: registryResourceId
    groupId: 'registry'
  }
  {
    key: 'blob'
    targetId: storageResourceId
    groupId: 'blob'
  }
  {
    key: 'sbns'
    targetId: serviceBusResourceId
    groupId: 'namespace'
  }
  {
    key: 'kv'
    targetId: keyVaultResourceId
    groupId: 'vault'
  }
]
var endpointNames = [for endpoint in endpoints: 'pe-${endpoint.key}-${projectName}-${suffix}']

// No privateDnsZoneGroup: the ALZ-lite DeployIfNotExists assignments own it. Post-deploy tests prove it landed.
module privateEndpoint 'br/public:avm/res/network/private-endpoint:0.12.1' = [
  for (endpoint, index) in endpoints: {
    name: 'avm-${endpointNames[index]}'
    params: {
      name: endpointNames[index]
      location: location
      tags: tags
      subnetResourceId: subnetId
      customNetworkInterfaceName: 'nic-${endpointNames[index]}'
      privateLinkServiceConnections: [
        {
          name: endpointNames[index]
          properties: {
            privateLinkServiceId: endpoint.targetId
            groupIds: [
              endpoint.groupId
            ]
          }
        }
      ]
    }
  }
]

resource privateEndpointRef 'Microsoft.Network/privateEndpoints@2025-05-01' existing = [
  for name in endpointNames: {
    name: name
  }
]

// Metrics only: private endpoints expose no log categories. Stable 2016-09-01 per owner decision; the pre-approved
// fallback is 2021-05-01-preview with AllMetrics if validate or what-if rejects it on privateEndpoints.
resource endpointMetrics 'Microsoft.Insights/diagnosticSettings@2016-09-01' = [
  for (name, index) in endpointNames: {
    name: 'service'
    scope: privateEndpointRef[index]
    location: location
    properties: {
      workspaceId: logAnalyticsWorkspaceId
      metrics: [
        {
          timeGrain: 'PT1M'
          enabled: true
        }
      ]
    }
    dependsOn: [
      privateEndpoint[index]
    ]
  }
]

output names array = endpointNames
