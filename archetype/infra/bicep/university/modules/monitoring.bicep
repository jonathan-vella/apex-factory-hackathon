@description('Application Insights component name.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Resource ID of the central log-management workspace.')
param logAnalyticsWorkspaceId string

@description('Principal ID of the web app identity that publishes telemetry.')
param uamiPrincipalId string

var monitoringMetricsPublisherRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '3913510d-42f4-4e42-8a64-420c390055eb'
)

// Ingestion and query stay public but Entra-authenticated (local auth off); this is the baseline Azure Monitor allowance.
module appInsights 'br/public:avm/res/insights/component:0.8.0' = {
  name: 'avm-${name}'
  params: {
    name: name
    location: location
    tags: tags
    kind: 'web'
    applicationType: 'web'
    workspaceResourceId: logAnalyticsWorkspaceId
    disableLocalAuth: true
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    roleAssignments: [
      {
        roleDefinitionIdOrName: monitoringMetricsPublisherRoleId
        principalId: uamiPrincipalId
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

output resourceId string = appInsights.outputs.resourceId
output name string = appInsights.outputs.name
@description('Endpoint metadata, not a credential (local auth is disabled).')
output connectionString string = appInsights.outputs.connectionString
