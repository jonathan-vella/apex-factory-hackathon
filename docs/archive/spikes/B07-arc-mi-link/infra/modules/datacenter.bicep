// The datacenter side of the B07 spike, in rg-datacenter: the peering to vnet-spike-mi and the MI link rules in nsg-servers.
// nsg-servers lists its rules inline in the datacenter Bicep, so re-running Deploy-Datacenter.ps1 removes these rules.

@description('Member index, used for vm-app01 at 10.10.n.4.')
@minValue(1)
@maxValue(20)
param memberIndex int

@description('Resource ID of vnet-spike-mi.')
param remoteVnetId string

@description('Address prefix of snet-sqlmi.')
param miSubnetPrefix string

var sqlServerIp = '10.10.${memberIndex}.4'

resource vnet 'Microsoft.Network/virtualNetworks@2025-09-01' existing = {
  name: 'vnet-datacenter'
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-09-01' existing = {
  name: 'nsg-servers'
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-09-01' = {
  parent: vnet
  name: 'peer-datacenter-to-spike-mi'
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// MI link: 5022 in from the MI subnet; 5022 and 11000-11999 out to it. Nothing else is opened.
resource miLinkInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2025-09-01' = {
  parent: nsg
  name: 'AllowMiLinkFromMiSubnetInbound'
  properties: {
    priority: 110
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourceAddressPrefix: miSubnetPrefix
    sourcePortRange: '*'
    destinationAddressPrefix: sqlServerIp
    destinationPortRange: '5022'
  }
}

resource miLinkOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2025-09-01' = {
  parent: nsg
  name: 'AllowMiLinkToMiSubnetOutbound'
  properties: {
    priority: 110
    direction: 'Outbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourceAddressPrefix: sqlServerIp
    sourcePortRange: '*'
    destinationAddressPrefix: miSubnetPrefix
    destinationPortRanges: [
      '5022'
      '11000-11999'
    ]
  }
  dependsOn: [
    miLinkInbound
  ]
}
