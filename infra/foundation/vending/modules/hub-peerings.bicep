// rg-hub side of the peerings: vnet-hub to the member's spoke and, if it exists, the datacenter.
param hubVnetName string
param memberIndex int
param spokeVnetId string

@description('Resource ID of vnet-datacenter. Empty: not peered.')
param datacenterVnetId string

resource hubVnet 'Microsoft.Network/virtualNetworks@2025-09-01' existing = {
  name: hubVnetName
}

resource toSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-09-01' = {
  parent: hubVnet
  name: 'peer-hub-to-spoke-${memberIndex}'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource toDatacenter 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-09-01' = if (!empty(datacenterVnetId)) {
  parent: hubVnet
  name: 'peer-hub-to-datacenter-${memberIndex}'
  properties: {
    remoteVirtualNetwork: {
      id: datacenterVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    toSpoke
  ]
}
