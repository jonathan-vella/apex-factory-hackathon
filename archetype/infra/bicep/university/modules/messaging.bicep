@description('Service Bus namespace name (6-50 characters, globally unique).')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Principal ID of the web app identity.')
param uamiPrincipalId string

@description('Object ID of the deploying user.')
param deployerObjectId string

var queueName = 'notifications'
var senderRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
)
var receiverRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
)

// zoneRedundant is not set: the pinned module always emits it (default true), accepted as platform-automatic in swedencentral.
module serviceBusNamespace 'br/public:avm/res/service-bus/namespace:0.17.1' = {
  name: 'avm-${name}'
  params: {
    name: name
    location: location
    tags: tags
    skuObject: {
      name: 'Premium'
      capacity: 1
    }
    disableLocalAuth: true
    minimumTlsVersion: '1.2'
    authorizationRules: []
    publicNetworkAccess: 'Disabled'
    networkRuleSets: {
      publicNetworkAccess: 'Disabled'
      defaultAction: 'Deny'
      trustedServiceAccessEnabled: false
    }
    queues: [
      {
        name: queueName
      }
    ]
    roleAssignments: [
      {
        roleDefinitionIdOrName: senderRoleId
        principalId: uamiPrincipalId
        principalType: 'ServicePrincipal'
      }
      {
        roleDefinitionIdOrName: receiverRoleId
        principalId: uamiPrincipalId
        principalType: 'ServicePrincipal'
      }
      {
        roleDefinitionIdOrName: senderRoleId
        principalId: deployerObjectId
        principalType: 'User'
      }
      {
        roleDefinitionIdOrName: receiverRoleId
        principalId: deployerObjectId
        principalType: 'User'
      }
    ]
  }
}

output resourceId string = serviceBusNamespace.outputs.resourceId
output name string = serviceBusNamespace.outputs.name
output fullyQualifiedNamespace string = '${serviceBusNamespace.outputs.name}.servicebus.windows.net'
output queueName string = queueName
