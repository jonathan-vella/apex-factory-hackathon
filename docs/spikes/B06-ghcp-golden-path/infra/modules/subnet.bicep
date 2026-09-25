// snet-pe-spike in vnet-datacenter (rg-datacenter), for the spike's private endpoints.

@description('Member index, used for the 10.10.n.128/27 prefix.')
@minValue(1)
@maxValue(20)
param memberIndex int

resource vnet 'Microsoft.Network/virtualNetworks@2025-09-01' existing = {
  name: 'vnet-datacenter'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2025-09-01' = {
  parent: vnet
  name: 'snet-pe-spike'
  properties: {
    addressPrefix: '10.10.${memberIndex}.128/27'
    defaultOutboundAccess: false
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

output subnetId string = subnet.id
output vnetId string = vnet.id
