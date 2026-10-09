@description('Web app name (globally unique DNS label).')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Resource ID of the App Service plan.')
param appServicePlanResourceId string

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

// Isolated in its own file so the security scanner can scope the public-web exception to exactly this declaration.
// Public HTTPS front end (requirement exception 1): no Easy Auth, no IP restrictions, basic publishing credentials off.
module site 'br/public:avm/res/web/site:0.24.0' = {
  name: 'avm-${name}'
  params: {
    name: name
    location: location
    tags: tags
    kind: 'app,linux,container'
    serverFarmResourceId: appServicePlanResourceId
    managedIdentities: {
      userAssignedResourceIds: [
        uamiResourceId
      ]
    }
    keyVaultAccessIdentityResourceId: uamiResourceId
    httpsOnly: true
    clientCertEnabled: false
    publicNetworkAccess: 'Enabled'
    virtualNetworkSubnetResourceId: subnetId
    outboundVnetRouting: {
      allTraffic: true
      imagePullTraffic: true
    }
    basicPublishingCredentialsPolicies: [
      {
        name: 'ftp'
        allow: false
      }
      {
        name: 'scm'
        allow: false
      }
    ]
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerImage}'
      acrUseManagedIdentityCreds: startsWith(containerImage, '${acrLoginServer}/')
      acrUserManagedIdentityID: uamiClientId
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
      healthCheckPath: '/'
      remoteDebuggingEnabled: false
    }
    configs: [
      {
        name: 'appsettings'
        properties: {
          WEBSITES_PORT: '8080'
          WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
          Storage__BlobServiceUri: storageBlobServiceUri
          Storage__ContainerName: containerName
          ServiceBus__FullyQualifiedNamespace: serviceBusFullyQualifiedNamespace
          ServiceBus__QueueName: serviceBusQueueName
          KeyVault__VaultUri: keyVaultUri
          APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString
          AZURE_CLIENT_ID: uamiClientId
        }
      }
    ]
  }
}

output name string = site.outputs.name
output resourceId string = site.outputs.resourceId
output defaultHostname string = site.outputs.defaultHostname
