// rg-spoke: vnet-spoke 10.20.n.0/24 with snet-app, snet-pe and snet-sqlmi, their route tables,
// nsg-sqlmi, and the peering to the hub. DNS points at the firewall (DNS proxy).
param location string
param memberIndex int
param hubVnetId string
param firewallPrivateIp string
param logAnalyticsWorkspaceId string

@description('nsg-sqlmi and rt-sqlmi already exist: leave them, and their MI-added rules and routes, alone.')
param miNetworkExists bool

var vnetPrefix = '10.20.${memberIndex}.0/24'
var appPrefix = '10.20.${memberIndex}.0/26'
var pePrefix = '10.20.${memberIndex}.64/26'
var miPrefix = '10.20.${memberIndex}.128/26'
var datacenterPrefix = '10.10.${memberIndex}.0/24'
var sqlServerIp = '10.10.${memberIndex}.4'

// SQL MI adds its own rules and routes (network intent policy). A PUT of nsg-sqlmi or rt-sqlmi would
// remove them, so they're created once, empty, and the kit's rules and routes are child resources.
module miNetwork 'sqlmi-network.bicep' = if (!miNetworkExists) {
  name: 'vending-sqlmi-network-${memberIndex}'
  params: {
    location: location
  }
}

resource miNsg 'Microsoft.Network/networkSecurityGroups@2025-09-01' existing = {
  name: 'nsg-sqlmi'
}

// MI link, from the B07 report: 5022 and 11000-11999 in from vm-app01, 5022 out to it.
resource miLinkInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2025-09-01' = {
  parent: miNsg
  name: 'AllowMiLinkFromSqlServerInbound'
  properties: {
    priority: 200
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourceAddressPrefix: sqlServerIp
    sourcePortRange: '*'
    destinationAddressPrefix: miPrefix
    destinationPortRanges: [
      '5022'
      '11000-11999'
    ]
  }
  dependsOn: [
    miNetwork
  ]
}

resource miLinkOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2025-09-01' = {
  parent: miNsg
  name: 'AllowMiLinkToSqlServerOutbound'
  properties: {
    priority: 200
    direction: 'Outbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourceAddressPrefix: miPrefix
    sourcePortRange: '*'
    destinationAddressPrefix: sqlServerIp
    destinationPortRange: '5022'
  }
  dependsOn: [
    miLinkInbound
  ]
}

resource miNsgDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: miNsg
  name: 'diag-log-management'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
  dependsOn: [
    miNetwork
  ]
}

resource appRouteTable 'Microsoft.Network/routeTables@2025-09-01' = {
  name: 'rt-app'
  location: location
  properties: {
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

resource peRouteTable 'Microsoft.Network/routeTables@2025-09-01' = {
  name: 'rt-pe'
  location: location
  properties: {
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

// Only the datacenter range goes to the firewall; MI keeps its own routes, including internet.
resource miRouteTable 'Microsoft.Network/routeTables@2025-09-01' existing = {
  name: 'rt-sqlmi'
}

resource miRouteToDatacenter 'Microsoft.Network/routeTables/routes@2025-09-01' = {
  parent: miRouteTable
  name: 'datacenter-to-firewall'
  properties: {
    addressPrefix: datacenterPrefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: firewallPrivateIp
  }
  dependsOn: [
    miNetwork
  ]
}

resource vnet 'Microsoft.Network/virtualNetworks@2025-09-01' = {
  name: 'vnet-spoke'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: [
        firewallPrivateIp
      ]
    }
  }
}

// Child subnets, one after the other, so a re-deploy keeps anything the archetype adds to them.
resource appSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-09-01' = {
  parent: vnet
  name: 'snet-app'
  properties: {
    addressPrefix: appPrefix
    defaultOutboundAccess: false
    privateEndpointNetworkPolicies: 'Disabled'
    routeTable: {
      id: appRouteTable.id
    }
    delegations: [
      {
        name: 'serverFarms'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
  }
}

resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-09-01' = {
  parent: vnet
  name: 'snet-pe'
  properties: {
    addressPrefix: pePrefix
    defaultOutboundAccess: false
    privateEndpointNetworkPolicies: 'Disabled'
    routeTable: {
      id: peRouteTable.id
    }
  }
  dependsOn: [
    appSubnet
  ]
}

resource miSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-09-01' = {
  parent: vnet
  name: 'snet-sqlmi'
  properties: {
    addressPrefix: miPrefix
    defaultOutboundAccess: false
    privateEndpointNetworkPolicies: 'Disabled'
    networkSecurityGroup: {
      id: miNsg.id
    }
    routeTable: {
      id: miRouteTable.id
    }
    delegations: [
      {
        name: 'managedInstances'
        properties: {
          serviceName: 'Microsoft.Sql/managedInstances'
        }
      }
    ]
  }
  dependsOn: [
    peSubnet
    miLinkOutbound
    miRouteToDatacenter
  ]
}

resource peeringToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-09-01' = {
  parent: vnet
  name: 'peer-spoke-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    miSubnet
  ]
}

output vnetId string = vnet.id
