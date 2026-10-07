@description('Container registry name (alphanumeric, globally unique).')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Principal ID of the web app identity that pulls images.')
param uamiPrincipalId string

@description('Object ID of the deploying user, who imports the placeholder image.')
param deployerObjectId string

var acrPullRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)
var acrPushRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '8311e382-0749-4cb8-b61a-304f252e45ec'
)
var acrImporterRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '577a9874-89fd-4f24-9dbd-b5034d0ad23a'
)

// zoneRedundancy is not set: the pinned module always sends 'Enabled' for Premium (az_posture decision, accepted).
module containerRegistry 'br/public:avm/res/container-registry/registry:0.13.1' = {
  name: 'avm-${name}'
  params: {
    name: name
    location: location
    tags: tags
    acrSku: 'Premium'
    acrAdminUserEnabled: false
    anonymousPullEnabled: false
    dataEndpointEnabled: false
    publicNetworkAccess: 'Disabled'
    // ADR-0004: owner-accepted trusted-services bypass so `az acr import` works against a network-restricted registry.
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSetDefaultAction: 'Deny'
    roleAssignmentMode: 'LegacyRegistryPermissions'
    retentionPolicyStatus: 'disabled'
    // The web app pulls with its UAMI, which needs ARM audience tokens; the module default is 'disabled'.
    azureADAuthenticationAsArmPolicyStatus: 'enabled'
    roleAssignments: [
      {
        roleDefinitionIdOrName: acrPullRoleId
        principalId: uamiPrincipalId
        principalType: 'ServicePrincipal'
      }
      {
        roleDefinitionIdOrName: acrPushRoleId
        principalId: deployerObjectId
        principalType: 'User'
      }
      {
        roleDefinitionIdOrName: acrImporterRoleId
        principalId: deployerObjectId
        principalType: 'User'
      }
    ]
  }
}

output resourceId string = containerRegistry.outputs.resourceId
output name string = containerRegistry.outputs.name
output loginServer string = containerRegistry.outputs.loginServer
