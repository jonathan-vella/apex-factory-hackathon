@description('Key Vault name (3-24 characters, globally unique).')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Principal ID of the web app identity that reads secrets.')
param uamiPrincipalId string

@description('Object ID of the deploying user, who writes the connection-string secret later.')
param deployerObjectId string

var secretsUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4633458b-17de-408a-b874-0445c86b69e6'
)
var secretsOfficerRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
)

// sku and enablePurgeProtection override the AVM defaults (premium, true). Purge protection stays off so a training teardown can be redone.
// No secret is created here; the migration step writes ConnectionStrings--DefaultConnection.
module keyVault 'br/public:avm/res/key-vault/vault:0.14.2' = {
  name: 'avm-${name}'
  params: {
    name: name
    location: location
    tags: tags
    sku: 'standard'
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: false
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
    enableVaultForDeployment: false
    enableVaultForDiskEncryption: false
    enableVaultForTemplateDeployment: false
    roleAssignments: [
      {
        roleDefinitionIdOrName: secretsUserRoleId
        principalId: uamiPrincipalId
        principalType: 'ServicePrincipal'
      }
      {
        roleDefinitionIdOrName: secretsOfficerRoleId
        principalId: deployerObjectId
        principalType: 'User'
      }
    ]
  }
}

output resourceId string = keyVault.outputs.resourceId
output name string = keyVault.outputs.name
output uri string = keyVault.outputs.uri
