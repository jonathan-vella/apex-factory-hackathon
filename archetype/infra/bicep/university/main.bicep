// University archetype (B09): one subscription-scope deployment that creates the archetype resource group and
// every workload resource in the vended spoke. It declares no VNet, subnet, NSG, route table or private DNS zone.
targetScope = 'subscription'

@description('Member-chosen uniqueness suffix, 4-6 lowercase letters or digits (preflight enforces the pattern). Sole uniqueness source in every name.')
@minLength(4)
@maxLength(6)
param suffix string

@description('Entra tenant ID. Preflight asserts it equals the signed-in tenant. Used by the SQL MI Entra administrator.')
param tenantId string

@description('Hub VNet region derived by preflight.')
@allowed([
  'swedencentral'
  'germanywestcentral'
])
param location string

@description('Resource ID of rg-management/log-management, derived by preflight. Used by Application Insights and the metrics settings.')
param logAnalyticsWorkspaceId string

@description('Resource ID of rg-management/id-sqlmi-directory in the shared services subscription, derived by preflight. SQL MI primary user-assigned identity.')
param sqlMiDirectoryIdentityId string

@description('Object ID of the signed-in deployer. SQL MI Entra admin SID and deployer data-plane roles.')
param deployerObjectId string

@description('UPN of the signed-in deployer. SQL MI Entra admin login.')
param deployerPrincipalName string

@description('Container image for the web app. The MCR placeholder is replaced by the ACR copy after deployment.')
param containerImage string = 'mcr.microsoft.com/dotnet/samples:aspnetapp-10.0'

@description('Windows time zone ID of the SQL MI start/stop schedule. Facilitator-adjustable.')
param sqlMiScheduleTimeZoneId string = 'W. Europe Standard Time'

@description('SQL MI schedule start time (HH:mm). Facilitator-adjustable.')
param sqlMiScheduleStartTime string = '07:30'

@description('SQL MI schedule stop time (HH:mm). Facilitator-adjustable.')
param sqlMiScheduleStopTime string = '18:30'

@description('Days on which the SQL MI schedule starts and stops the instance. Facilitator-adjustable.')
param sqlMiScheduleDays array = [
  'Monday'
  'Tuesday'
  'Wednesday'
  'Thursday'
  'Friday'
]

var projectName = 'university'
var rgName = 'rg-${projectName}-${suffix}'

// No tag policy was discovered, so the Step 1 convention (APEX fallback set) applies to the RG and every resource created.
var tags = {
  environment: 'dev'
  owner: 'lab-admin'
  costcenter: 'apex-factory'
  application: projectName
  workload: projectName
  sla: 'best-effort'
  'backup-policy': 'platform-default'
  'maint-window': 'system-default'
  'technical-contact': 'ghostbusters'
}

// The vended spoke is referenced by ID only; it is never declared or modified here.
var spokeResourceGroupName = 'rg-spoke'
var spokeVnetName = 'vnet-spoke'
var snetAppId = resourceId(
  subscription().subscriptionId,
  spokeResourceGroupName,
  'Microsoft.Network/virtualNetworks/subnets',
  spokeVnetName,
  'snet-app'
)
var snetPeId = resourceId(
  subscription().subscriptionId,
  spokeResourceGroupName,
  'Microsoft.Network/virtualNetworks/subnets',
  spokeVnetName,
  'snet-pe'
)
var snetSqlMiId = resourceId(
  subscription().subscriptionId,
  spokeResourceGroupName,
  'Microsoft.Network/virtualNetworks/subnets',
  spokeVnetName,
  'snet-sqlmi'
)

var names = {
  identity: 'id-${projectName}-${suffix}'
  appInsights: 'appi-${projectName}-${suffix}'
  registry: 'cr${projectName}${suffix}'
  storage: 'st${projectName}${suffix}'
  serviceBus: 'sbns-${projectName}-${suffix}'
  keyVault: 'kv-${projectName}-${suffix}'
  sqlMi: 'sqlmi-${projectName}-${suffix}'
  appServicePlan: 'asp-${projectName}-${suffix}'
  webApp: 'app-${projectName}-${suffix}'
}

module workloadRg 'br/public:avm/res/resources/resource-group:0.4.4' = {
  name: 'resource-group'
  params: {
    name: rgName
    location: location
    tags: tags
  }
}

module identity 'modules/identity.bicep' = {
  name: 'identity'
  scope: resourceGroup(rgName)
  params: {
    name: names.identity
    location: location
    tags: tags
  }
  dependsOn: [
    workloadRg
  ]
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup(rgName)
  params: {
    name: names.appInsights
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    uamiPrincipalId: identity.outputs.principalId
  }
}

module registry 'modules/registry.bicep' = {
  name: 'registry'
  scope: resourceGroup(rgName)
  params: {
    name: names.registry
    location: location
    tags: tags
    uamiPrincipalId: identity.outputs.principalId
    deployerObjectId: deployerObjectId
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  scope: resourceGroup(rgName)
  params: {
    name: names.storage
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    uamiPrincipalId: identity.outputs.principalId
    deployerObjectId: deployerObjectId
  }
}

module messaging 'modules/messaging.bicep' = {
  name: 'messaging'
  scope: resourceGroup(rgName)
  params: {
    name: names.serviceBus
    location: location
    tags: tags
    uamiPrincipalId: identity.outputs.principalId
    deployerObjectId: deployerObjectId
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  scope: resourceGroup(rgName)
  params: {
    name: names.keyVault
    location: location
    tags: tags
    uamiPrincipalId: identity.outputs.principalId
    deployerObjectId: deployerObjectId
  }
}

module sqlMi 'modules/sql-mi.bicep' = {
  name: 'sql-mi'
  scope: resourceGroup(rgName)
  params: {
    name: names.sqlMi
    location: location
    tags: tags
    subnetId: snetSqlMiId
    tenantId: tenantId
    adminLogin: deployerPrincipalName
    adminObjectId: deployerObjectId
    directoryIdentityId: sqlMiDirectoryIdentityId
    scheduleTimeZoneId: sqlMiScheduleTimeZoneId
    scheduleStartTime: sqlMiScheduleStartTime
    scheduleStopTime: sqlMiScheduleStopTime
    scheduleDays: sqlMiScheduleDays
  }
  dependsOn: [
    workloadRg
  ]
}

module privateEndpoints 'modules/private-endpoints.bicep' = {
  name: 'private-endpoints'
  scope: resourceGroup(rgName)
  params: {
    suffix: suffix
    projectName: projectName
    location: location
    tags: tags
    subnetId: snetPeId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    registryResourceId: registry.outputs.resourceId
    storageResourceId: storage.outputs.resourceId
    serviceBusResourceId: messaging.outputs.resourceId
    keyVaultResourceId: keyVault.outputs.resourceId
  }
}

// Role assignments live in the identity-consuming modules above, so consuming their outputs orders them before the app.
module web 'modules/web.bicep' = {
  name: 'web'
  scope: resourceGroup(rgName)
  params: {
    appServicePlanName: names.appServicePlan
    webAppName: names.webApp
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    subnetId: snetAppId
    uamiResourceId: identity.outputs.resourceId
    uamiClientId: identity.outputs.clientId
    containerImage: containerImage
    acrLoginServer: registry.outputs.loginServer
    storageBlobServiceUri: storage.outputs.primaryBlobEndpoint
    containerName: storage.outputs.containerName
    serviceBusFullyQualifiedNamespace: messaging.outputs.fullyQualifiedNamespace
    serviceBusQueueName: messaging.outputs.queueName
    keyVaultUri: keyVault.outputs.uri
    appInsightsConnectionString: monitoring.outputs.connectionString
  }
  dependsOn: [
    privateEndpoints
  ]
}

output resourceGroupName string = rgName
output webAppName string = web.outputs.name
output webAppDefaultHostname string = web.outputs.defaultHostname
output acrName string = registry.outputs.name
output acrLoginServer string = registry.outputs.loginServer
output uamiClientId string = identity.outputs.clientId
output sqlMiName string = sqlMi.outputs.name
output sqlMiFqdn string = sqlMi.outputs.fullyQualifiedDomainName
output storageAccountName string = storage.outputs.name
output serviceBusNamespaceName string = messaging.outputs.name
output keyVaultName string = keyVault.outputs.name
output keyVaultUri string = keyVault.outputs.uri
output privateEndpointNames array = privateEndpoints.outputs.names
