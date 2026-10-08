@description('Storage account name (3-24 lowercase alphanumeric, globally unique).')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Resource ID of the central log-management workspace.')
param logAnalyticsWorkspaceId string

@description('Principal ID of the web app identity.')
param uamiPrincipalId string

@description('Object ID of the deploying user.')
param deployerObjectId string

var containerName = 'teaching-materials'
var storageBlobDataContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
)

// skuName, allowSharedKeyAccess and defaultToOAuthAuthentication override the AVM defaults (Standard_GRS, true, false).
module storageAccount 'br/public:avm/res/storage/storage-account:0.33.1' = {
  name: 'avm-${name}'
  params: {
    name: name
    location: location
    tags: tags
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    accessTier: 'Hot'
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowCrossTenantReplication: false
    isLocalUserEnabled: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
    blobServices: {
      containers: [
        {
          name: containerName
          publicAccess: 'None'
        }
      ]
    }
    roleAssignments: [
      {
        roleDefinitionIdOrName: storageBlobDataContributorRoleId
        principalId: uamiPrincipalId
        principalType: 'ServicePrincipal'
      }
      {
        roleDefinitionIdOrName: storageBlobDataContributorRoleId
        principalId: deployerObjectId
        principalType: 'User'
      }
    ]
  }
}

resource account 'Microsoft.Storage/storageAccounts@2025-06-01' existing = {
  name: name
}

// Account-level metrics only: the DINE assignment owns the blob-service logs, so none are declared here.
resource accountMetrics 'Microsoft.Insights/diagnosticSettings@2016-09-01' = {
  name: 'service'
  scope: account
  location: location
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        timeGrain: 'PT1M'
        enabled: true
      }
    ]
  }
  dependsOn: [
    storageAccount
  ]
}

output resourceId string = storageAccount.outputs.resourceId
output name string = storageAccount.outputs.name
output primaryBlobEndpoint string = storageAccount.outputs.primaryBlobEndpoint
output containerName string = containerName
