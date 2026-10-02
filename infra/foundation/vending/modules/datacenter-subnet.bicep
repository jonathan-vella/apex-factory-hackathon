// snet-servers with B04's settings, read from the live subnet, plus rt-servers. defaultOutboundAccess stays
// off, as in B04.
param vnetName string
param addressPrefix string
param natGatewayId string
param networkSecurityGroupId string
param privateEndpointNetworkPolicies string
param routeTableId string

resource vnet 'Microsoft.Network/virtualNetworks@2025-09-01' existing = {
  name: vnetName
}

resource serversSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-09-01' = {
  parent: vnet
  name: 'snet-servers'
  properties: {
    addressPrefix: addressPrefix
    defaultOutboundAccess: false
    privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
    natGateway: {
      id: natGatewayId
    }
    networkSecurityGroup: {
      id: networkSecurityGroupId
    }
    routeTable: {
      id: routeTableId
    }
  }
}
