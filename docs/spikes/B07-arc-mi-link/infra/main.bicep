// B07 spike: the MI link target. vnet-spike-mi peered with vnet-datacenter, and a General Purpose SQL MI.
// Deploy into an existing rg-spike-b07. Zones: none set, zone redundancy off (backlog conventions).
// Paid MI, not the free offer (owner decision, 2026-10-02): about $0.68/hour with Azure Hybrid Benefit.
targetScope = 'resourceGroup'

@description('Azure region. Fallback: germanywestcentral.')
param location string = resourceGroup().location

@description('Member index n, 1-20. vnet-spike-mi is 10.20.n.0/24 and vm-app01 is 10.10.n.4.')
@minValue(1)
@maxValue(20)
param memberIndex int = 1

@description('Unique member suffix, 4-6 lowercase letters and digits.')
@minLength(4)
@maxLength(6)
param suffix string

@description('User principal name of the owner, the MI Entra admin.')
param adminLogin string

@description('Object ID of the owner, the MI Entra admin.')
@minLength(36)
@maxLength(36)
param adminObjectId string

@description('BasePrice is Azure Hybrid Benefit (on by default; assumes eligible SQL Server licences). LicenseIncluded turns it off.')
@allowed([
  'BasePrice'
  'LicenseIncluded'
])
param licenseType string = 'BasePrice'

@description('Resource group of the datacenter VNet and nsg-servers.')
param datacenterResourceGroup string = 'rg-datacenter'

var vnetPrefix = '10.20.${memberIndex}.0/24'
var miSubnetPrefix = '10.20.${memberIndex}.128/26'
var sqlServerIp = '10.10.${memberIndex}.4'

resource datacenterVnet 'Microsoft.Network/virtualNetworks@2025-09-01' existing = {
  scope: resourceGroup(datacenterResourceGroup)
  name: 'vnet-datacenter'
}

// MI adds its own rules and routes (network intent policy), so neither resource lists them inline.
resource nsg 'Microsoft.Network/networkSecurityGroups@2025-09-01' = {
  name: 'nsg-sqlmi'
  location: location
}

// MI link: 5022 and 11000-11999 in from the SQL Server, 5022 out to it. Nothing else is opened.
resource miLinkInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2025-09-01' = {
  parent: nsg
  name: 'AllowMiLinkFromSqlServerInbound'
  properties: {
    priority: 200
    direction: 'Inbound'
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
}

resource miLinkOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2025-09-01' = {
  parent: nsg
  name: 'AllowMiLinkToSqlServerOutbound'
  properties: {
    priority: 200
    direction: 'Outbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourceAddressPrefix: miSubnetPrefix
    sourcePortRange: '*'
    destinationAddressPrefix: sqlServerIp
    destinationPortRange: '5022'
  }
  dependsOn: [
    miLinkInbound
  ]
}

resource routeTable 'Microsoft.Network/routeTables@2025-09-01' = {
  name: 'rt-sqlmi'
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2025-09-01' = {
  name: 'vnet-spike-mi'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetPrefix
      ]
    }
  }
}

resource miSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-09-01' = {
  parent: vnet
  name: 'snet-sqlmi'
  properties: {
    addressPrefix: miSubnetPrefix
    defaultOutboundAccess: false
    networkSecurityGroup: {
      id: nsg.id
    }
    routeTable: {
      id: routeTable.id
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
}

resource peeringToDatacenter 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-09-01' = {
  parent: vnet
  name: 'peer-spike-mi-to-datacenter'
  properties: {
    remoteVirtualNetwork: {
      id: datacenterVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    miSubnet
  ]
}

module datacenter 'modules/datacenter.bicep' = {
  scope: resourceGroup(datacenterResourceGroup)
  name: 'spike-b07-datacenter'
  params: {
    memberIndex: memberIndex
    remoteVnetId: vnet.id
    miSubnetPrefix: miSubnetPrefix
  }
  dependsOn: [
    peeringToDatacenter
  ]
}

// General Purpose, Standard-series (Gen5), 4 vCores, 64 GB. Paid, not the free offer.
resource managedInstance 'Microsoft.Sql/managedInstances@2025-01-01' = {
  name: 'sqlmi-university-${suffix}-b07'
  location: location
  sku: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 4
  }
  properties: {
    subnetId: miSubnet.id
    vCores: 4
    storageSizeInGB: 64
    licenseType: licenseType
    databaseFormat: 'SQLServer2022'
    timezoneId: 'W. Europe Standard Time'
    zoneRedundant: false
    publicDataEndpointEnabled: false
    minimalTlsVersion: '1.2'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: adminLogin
      sid: adminObjectId
      tenantId: tenant().tenantId
      azureADOnlyAuthentication: true
    }
  }
  dependsOn: [
    miLinkOutbound
    datacenter
  ]
}

output managedInstanceName string = managedInstance.name
output managedInstanceFqdn string = managedInstance.properties.fullyQualifiedDomainName
output miSubnetPrefix string = miSubnetPrefix
