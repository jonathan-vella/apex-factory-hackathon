// Datacenter network: VNet, server subnet, NSG, NAT gateway and Bastion Developer.

@description('Azure region.')
param location string

@description('Member index, used for the 10.10.n.0/24 address space.')
@minValue(1)
@maxValue(20)
param memberIndex int

var vnetPrefix = '10.10.${memberIndex}.0/24'
var serversPrefix = '10.10.${memberIndex}.0/25'

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-09-01' = {
  name: 'nsg-servers'
  location: location
  properties: {
    securityRules: [
      {
        // Bastion Developer reaches the VMs from the Azure platform address, not from a subnet in the VNet.
        name: 'AllowBastionDeveloperRdpInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '168.63.129.16'
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
    subnets: [
      {
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
    ]
  }
}

// Developer SKU: free, shared pool, no AzureBastionSubnet and no public IP.
resource bastion 'Microsoft.Network/bastionHosts@2025-09-01' = {
  name: 'bas-datacenter'
  location: location
  sku: {
    name: 'Developer'
  }
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
  }
}

output subnetId string = vnet.properties.subnets[0].id
output bastionName string = bastion.name
