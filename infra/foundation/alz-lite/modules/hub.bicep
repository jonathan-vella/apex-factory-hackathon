// rg-hub: vnet-hub, Azure Firewall Standard with DNS proxy, and the central privatelink DNS zones.
// Zones: none set. afw-hub has no zone; pip-afw-hub (Standard) is zone-redundant automatically.
param location string
param logAnalyticsWorkspaceId string
param extraSnatPrefixes array = []

// Verified on https://learn.microsoft.com/azure/private-link/private-endpoint-dns (2026-10-02).
// ACR's data endpoints register in privatelink.azurecr.io too.
var dnsZones = [
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.servicebus.windows.net'
  'privatelink.azurecr.io'
  'privatelink.vaultcore.azure.net'
]

resource vnet 'Microsoft.Network/virtualNetworks@2025-09-01' = {
  name: 'vnet-hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.100.0.0/26'
        }
      }
    ]
  }
}

resource firewallPip 'Microsoft.Network/publicIPAddresses@2025-09-01' = {
  name: 'pip-afw-hub'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

module firewallPolicy 'firewall-policy.bicep' = {
  name: 'alz-lite-firewall-policy'
  params: {
    location: location
    extraSnatPrefixes: extraSnatPrefixes
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2025-09-01' = {
  name: 'afw-hub'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: firewallPolicy.outputs.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'AzureFirewallSubnet')
          }
          publicIPAddress: {
            id: firewallPip.id
          }
        }
      }
    ]
  }
}

// diagnosticSettings has no GA API version for extension resources: 2021-05-01-preview is the current one.
resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: firewall
  name: 'diag-log-management'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource zones 'Microsoft.Network/privateDnsZones@2024-06-01' = [
  for zone in dnsZones: {
    name: zone
    location: 'global'
  }
]

resource zoneLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [
  for (zone, i) in dnsZones: {
    parent: zones[i]
    name: 'link-vnet-hub'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
]

output vnetId string = vnet.id
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPolicyId string = firewallPolicy.outputs.id
output dnsZoneIds object = {
  blob: zones[0].id
  serviceBus: zones[1].id
  containerRegistry: zones[2].id
  keyVault: zones[3].id
}
