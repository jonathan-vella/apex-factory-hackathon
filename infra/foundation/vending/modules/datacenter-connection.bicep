// rg-datacenter side: peering to the hub, rt-servers on snet-servers (spoke range to the firewall,
// internet stays on the NAT gateway), then vnet-datacenter's DNS servers set to the firewall.
// A datacenter redeploy (scripts/Deploy-Datacenter.ps1) resets the subnet and the DNS servers:
// re-run vending afterwards.
param location string
param memberIndex int
param hubVnetId string
param firewallPrivateIp string

var block = memberIndex / 256
var spokeOct2 = block == 0 ? 20 : 191 + block
var oct3 = memberIndex % 256
var spokePrefix = '10.${spokeOct2}.${oct3}.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2025-09-01' existing = {
  name: 'vnet-datacenter'
}

resource serversSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-09-01' existing = {
  parent: vnet
  name: 'snet-servers'
}

resource peeringToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-09-01' = {
  parent: vnet
  name: 'peer-datacenter-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource serversRouteTable 'Microsoft.Network/routeTables@2025-09-01' = {
  name: 'rt-servers'
  location: location
  properties: {
    routes: [
      {
        name: 'spoke-to-firewall'
        properties: {
          addressPrefix: spokePrefix
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

// The subnet keeps B04's settings (read from the live subnet) and gains the route table.
module serversRoute 'datacenter-subnet.bicep' = {
  name: 'vending-datacenter-subnet-${memberIndex}'
  params: {
    vnetName: vnet.name
    addressPrefix: serversSubnet.properties.addressPrefix
    natGatewayId: serversSubnet.properties.natGateway.id
    networkSecurityGroupId: serversSubnet.properties.networkSecurityGroup.id
    privateEndpointNetworkPolicies: serversSubnet.properties.privateEndpointNetworkPolicies
    routeTableId: serversRouteTable.id
  }
  dependsOn: [
    peeringToHub
  ]
}

module dns 'datacenter-dns.bicep' = {
  name: 'vending-datacenter-dns-${memberIndex}'
  params: {
    location: location
    addressPrefixes: vnet.properties.addressSpace.addressPrefixes
    dnsServer: firewallPrivateIp
  }
  dependsOn: [
    serversRoute
  ]
}
