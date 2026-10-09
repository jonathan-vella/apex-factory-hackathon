// Datacenter network: VNet, server and Bastion subnets, NSG, NAT gateway and Bastion Standard.

@description('Azure region.')
param location string

@description('Member index, used for the 10.10.n.0/24 address space.')
@minValue(1)
@maxValue(20)
param memberIndex int

var vnetPrefix = '10.10.${memberIndex}.0/24'
var serversPrefix = '10.10.${memberIndex}.0/25'
// 10.10.n.128/27 stays free for B06's snet-pe-spike.
var bastionPrefix = '10.10.${memberIndex}.192/26'

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-09-01' = {
  name: 'nsg-servers'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowBastionRdpInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: bastionPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: serversPrefix
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

// No zones: Standard public IPs are zone-redundant automatically in regions with zones.
resource natPip 'Microsoft.Network/publicIPAddresses@2025-09-01' = {
  name: 'pip-nat-datacenter'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource nat 'Microsoft.Network/natGateways@2025-09-01' = {
  name: 'nat-datacenter'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: natPip.id
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2025-09-01' = {
  name: 'vnet-datacenter'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetPrefix
      ]
    }
  }
}

// Subnets are child resources and the VNet has no subnets property, so a re-deploy keeps subnets
// that later items add (B06's snet-pe-spike). They deploy one after the other to avoid conflicts.
resource serversSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-09-01' = {
  parent: vnet
  name: 'snet-servers'
  properties: {
    addressPrefix: serversPrefix
    defaultOutboundAccess: false
    natGateway: {
      id: nat.id
    }
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// No NSG and no route table.
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-09-01' = {
  parent: vnet
  name: 'AzureBastionSubnet'
  properties: {
    addressPrefix: bastionPrefix
  }
  dependsOn: [
    serversSubnet
  ]
}

// No zones: Standard public IPs are zone-redundant automatically in regions with zones.
resource bastionPip 'Microsoft.Network/publicIPAddresses@2025-09-01' = {
  name: 'pip-bas-datacenter'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Standard SKU, never Developer. Native client support (enableTunneling) lets members connect with
// their local RDP client through az network bastion rdp.
resource bastion 'Microsoft.Network/bastionHosts@2025-09-01' = {
  name: 'bas-datacenter'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
  }
}

output subnetId string = serversSubnet.id
output bastionName string = bastion.name
