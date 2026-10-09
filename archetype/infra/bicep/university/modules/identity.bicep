@description('User-assigned identity name.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

module identity 'br/public:avm/res/managed-identity/user-assigned-identity:0.6.0' = {
  name: 'avm-${name}'
  params: {
    name: name
    location: location
    tags: tags
  }
}

output resourceId string = identity.outputs.resourceId
output principalId string = identity.outputs.principalId
output clientId string = identity.outputs.clientId
output name string = identity.outputs.name
