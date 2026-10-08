@description('App Service plan name.')
param appServicePlanName string

@description('Web app name (globally unique DNS label).')
param webAppName string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Resource ID of the central log-management workspace.')
param logAnalyticsWorkspaceId string

@description('Resource ID of the vended app-integration subnet (snet-app).')
param subnetId string

@description('Resource ID of the web app user-assigned identity.')
param uamiResourceId string

@description('Client ID of the web app user-assigned identity.')
param uamiClientId string

@description('Container image. Starts on the MCR placeholder; postprovision switches it to the ACR copy.')
param containerImage string

@description('ACR login server, used to detect an image that must be pulled with the managed identity.')
param acrLoginServer string

@description('Blob service endpoint of the storage account.')
param storageBlobServiceUri string

@description('Blob container name.')
param containerName string

@description('Fully qualified Service Bus namespace host name.')
param serviceBusFullyQualifiedNamespace string

@description('Service Bus queue name.')
param serviceBusQueueName string

@description('Key Vault URI.')
param keyVaultUri string

@description('Application Insights connection string (endpoint metadata, not a credential).')
param appInsightsConnectionString string

// skuCapacity and zoneRedundant override the AVM defaults (3 and true for P SKUs): one instance, no zone redundancy.
module appServicePlan 'br/public:avm/res/web/serverfarm:0.7.0' = {
  name: 'avm-${appServicePlanName}'
  params: {
    name: appServicePlanName
    location: location
    tags: tags
    kind: 'linux'
    skuName: 'P0v3'
    skuCapacity: 1
    zoneRedundant: false
  }
}

resource planRef 'Microsoft.Web/serverfarms@2025-03-01' existing = {
  name: appServicePlanName
}

// The plan has no logs category group covered by the DINE assignments, so the archetype owns its metrics setting.
resource planMetrics 'Microsoft.Insights/diagnosticSettings@2016-09-01' = {
  name: 'service'
  scope: planRef
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
    appServicePlan
  ]
}

module webApp 'web-app.bicep' = {
  name: 'web-app'
  params: {
    name: webAppName
    location: location
    tags: tags
    appServicePlanResourceId: appServicePlan.outputs.resourceId
    subnetId: subnetId
    uamiResourceId: uamiResourceId
    uamiClientId: uamiClientId
    containerImage: containerImage
    acrLoginServer: acrLoginServer
    storageBlobServiceUri: storageBlobServiceUri
    containerName: containerName
    serviceBusFullyQualifiedNamespace: serviceBusFullyQualifiedNamespace
    serviceBusQueueName: serviceBusQueueName
    keyVaultUri: keyVaultUri
    appInsightsConnectionString: appInsightsConnectionString
  }
}

output name string = webApp.outputs.name
output resourceId string = webApp.outputs.resourceId
output defaultHostname string = webApp.outputs.defaultHostname
