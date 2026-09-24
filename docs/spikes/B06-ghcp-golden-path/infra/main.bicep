// B06 spike: the Azure services the modernized Contoso University uses, private-only, in rg-spike-b06.
// Deploy into an existing rg-spike-b06; the private endpoints go into snet-pe-spike of vnet-datacenter.
// Zones: none set. Service Bus Premium and ACR Premium are zone-redundant automatically (backlog conventions).
targetScope = 'resourceGroup'

@description('Azure region. Fallback: germanywestcentral.')
param location string = resourceGroup().location

@description('Member index n, 1-20. snet-pe-spike is 10.10.n.128/27.')
@minValue(1)
@maxValue(20)
param memberIndex int = 1

@description('Unique member suffix, 4-6 lowercase letters and digits.')
@minLength(4)
@maxLength(6)
param suffix string

@description('Object ID of the owner, who gets the data-plane roles for local runs from vm-dev01.')
param ownerObjectId string

@description('Principal type of ownerObjectId.')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param ownerPrincipalType string = 'User'

@description('Resource group of the datacenter VNet.')
param datacenterResourceGroup string = 'rg-datacenter'

var roles = {
  storageBlobDataContributor: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  serviceBusDataSender: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
  serviceBusDataReceiver: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
  acrPush: '8311e382-0749-4cb8-b61a-304f252e45ec'
  keyVaultSecretsOfficer: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
}

module subnet 'modules/subnet.bicep' = {
  scope: resourceGroup(datacenterResourceGroup)
  name: 'spike-b06-subnet'
  params: {
    memberIndex: memberIndex
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2025-08-01' = {
  name: 'stuni${suffix}b06'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-08-01' = {
  parent: storage
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-08-01' = {
  parent: blobService
  name: 'teaching-materials'
  properties: {
    publicAccess: 'None'
  }
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: 'sbns-uni-${suffix}-b06'
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 1
  }
  properties: {
    disableLocalAuth: true
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2024-01-01' = {
  parent: serviceBus
  name: 'notifications'
}

resource registry 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: 'cruni${suffix}b06'
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'None'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: 'kv-uni-${suffix}-b06'
  location: location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
  }
}

// One private endpoint and one private DNS zone per service.
var endpoints = [
  {
    name: 'pe-${storage.name}-blob'
    resourceId: storage.id
    groupId: 'blob'
    zone: 'privatelink.blob.${environment().suffixes.storage}'
  }
  {
    name: 'pe-${serviceBus.name}'
    resourceId: serviceBus.id
    groupId: 'namespace'
    zone: 'privatelink.servicebus.windows.net'
  }
  {
    name: 'pe-${registry.name}'
    resourceId: registry.id
    groupId: 'registry'
    zone: 'privatelink.azurecr.io'
  }
  {
    name: 'pe-${keyVault.name}'
    resourceId: keyVault.id
    groupId: 'vault'
    zone: 'privatelink.vaultcore.azure.net'
  }
]

resource zones 'Microsoft.Network/privateDnsZones@2024-06-01' = [
  for endpoint in endpoints: {
    name: endpoint.zone
    location: 'global'
  }
]

resource zoneLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [
  for (endpoint, i) in endpoints: {
    parent: zones[i]
    name: 'link-vnet-datacenter'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: subnet.outputs.vnetId
      }
    }
  }
]

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2025-09-01' = [
  for endpoint in endpoints: {
    name: endpoint.name
    location: location
    properties: {
      subnet: {
        id: subnet.outputs.subnetId
      }
      privateLinkServiceConnections: [
        {
          name: endpoint.name
          properties: {
            privateLinkServiceId: endpoint.resourceId
            groupIds: [
              endpoint.groupId
            ]
          }
        }
      ]
    }
  }
]

resource zoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-09-01' = [
  for (endpoint, i) in endpoints: {
    parent: privateEndpoints[i]
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: replace(endpoint.zone, '.', '-')
          properties: {
            privateDnsZoneId: zones[i].id
          }
        }
      ]
    }
  }
]

resource blobRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storage
  name: guid(storage.id, ownerObjectId, roles.storageBlobDataContributor)
  properties: {
    principalId: ownerObjectId
    principalType: ownerPrincipalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.storageBlobDataContributor)
  }
}

resource serviceBusRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in [roles.serviceBusDataSender, roles.serviceBusDataReceiver]: {
    scope: serviceBus
    name: guid(serviceBus.id, ownerObjectId, role)
    properties: {
      principalId: ownerObjectId
      principalType: ownerPrincipalType
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role)
    }
  }
]

resource acrRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: registry
  name: guid(registry.id, ownerObjectId, roles.acrPush)
  properties: {
    principalId: ownerObjectId
    principalType: ownerPrincipalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.acrPush)
  }
}

resource keyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, ownerObjectId, roles.keyVaultSecretsOfficer)
  properties: {
    principalId: ownerObjectId
    principalType: ownerPrincipalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.keyVaultSecretsOfficer)
  }
}

output storageAccountName string = storage.name
output blobEndpoint string = storage.properties.primaryEndpoints.blob
output blobContainerName string = container.name
output serviceBusNamespace string = serviceBus.name
output serviceBusHost string = '${serviceBus.name}.servicebus.windows.net'
output queueName string = queue.name
output registryName string = registry.name
output registryLoginServer string = registry.properties.loginServer
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
