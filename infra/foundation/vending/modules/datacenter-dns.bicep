// vnet-datacenter's DNS servers set to the firewall (DNS proxy). Like B04's template, it has no
// subnets property, so the subnets and peerings stay. Running VMs pick it up after a restart or
// ipconfig /renew.
param location string
param addressPrefixes array
param dnsServer string

resource vnet 'Microsoft.Network/virtualNetworks@2025-09-01' = {
  name: 'vnet-datacenter'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    dhcpOptions: {
      dnsServers: [
        dnsServer
      ]
    }
  }
}
