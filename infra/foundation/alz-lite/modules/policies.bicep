// ALZ-lite core policies at mg-factory-corp. Built-in definitions only, display names prefixed ALZ-lite:.
// Definition IDs were checked with az policy definition list on 2026-10-02 (infra/foundation/README.md).
targetScope = 'managementGroup'

param location string
param allowedLocations array

@description('Resource IDs of the central privatelink zones: blob, serviceBus, containerRegistry, keyVault.')
param dnsZoneIds object

param logAnalyticsWorkspaceId string

var networkContributor = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var logAnalyticsContributor = '92aaf0da-9dab-42b6-94a3-d43ce8d16293'
var monitoringContributor = '749f88d5-cbae-40b8-bcfc-e573ddc772fa'

var corePolicies = [
  {
    name: 'alzl-allowed-locations'
    displayName: 'ALZ-lite: Allowed locations'
    definitionId: 'e56962a6-4747-49cd-b67b-bf8b01975c4c'
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
      // Audit, not Deny (owner decision 2026-10-06): flags other regions without blocking them.
      effect: {
        value: 'Audit'
      }
    }
  }
  {
    name: 'alzl-location-match-rg'
    displayName: 'ALZ-lite: Audit resource location matches resource group location'
    definitionId: '0a914e76-4921-4c19-b460-a2d36003525a'
    parameters: {
      effect: {
        value: 'Audit'
      }
    }
  }
  {
    name: 'alzl-deny-nic-pip'
    displayName: 'ALZ-lite: Network interfaces should not have public IPs'
    definitionId: '83a86a26-fd1f-447c-b59d-e51f44264114'
    parameters: {}
  }
  {
    name: 'alzl-deny-pna-storage'
    displayName: 'ALZ-lite: Storage accounts should disable public network access'
    definitionId: 'b2982f36-99f2-4db5-8eff-283140c09693'
    parameters: {
      effect: {
        value: 'Deny'
      }
    }
  }
  {
    name: 'alzl-deny-pna-keyvault'
    displayName: 'ALZ-lite: Azure Key Vault should disable public network access'
    definitionId: '405c5871-3e91-4644-8a63-58e19d68ff5b'
    parameters: {
      effect: {
        value: 'Deny'
      }
    }
  }
  {
    name: 'alzl-deny-pna-servicebus'
    displayName: 'ALZ-lite: Service Bus Namespaces should disable public network access'
    definitionId: 'cbd11fd3-3002-4907-b6c8-579f0e700e13'
    parameters: {
      effect: {
        value: 'Deny'
      }
    }
  }
  {
    name: 'alzl-deny-pna-acr'
    displayName: 'ALZ-lite: Public network access should be disabled for Container registries'
    definitionId: '0fdf0491-d080-4575-b627-ad0e843cba0f'
    parameters: {
      effect: {
        value: 'Deny'
      }
    }
  }
  {
    name: 'alzl-deny-pna-sqlmi'
    displayName: 'ALZ-lite: Azure SQL Managed Instances should disable public network access'
    definitionId: '9dfea752-dd46-4766-aed1-c355fa93fb91'
    parameters: {
      effect: {
        value: 'Deny'
      }
    }
  }
]

// Private endpoints register in the central zones. Not for SQL MI: it has no private endpoint here.
var dnsPolicies = [
  {
    name: 'alzl-dns-blob'
    displayName: 'ALZ-lite: Configure a private DNS Zone ID for blob groupID'
    definitionId: '75973700-529f-4de2-b794-fb9b6781b6b0'
    zoneId: dnsZoneIds.blob
  }
  {
    name: 'alzl-dns-servicebus'
    displayName: 'ALZ-lite: Configure Service Bus namespaces to use private DNS zones'
    definitionId: 'f0fcf93c-c063-4071-9668-c47474bd3564'
    zoneId: dnsZoneIds.serviceBus
  }
  {
    name: 'alzl-dns-acr'
    displayName: 'ALZ-lite: Configure Container registries to use private DNS zones'
    definitionId: 'e9585a95-5b8c-4d03-b193-dc7eb5ac4c32'
    zoneId: dnsZoneIds.containerRegistry
  }
  {
    name: 'alzl-dns-keyvault'
    displayName: 'ALZ-lite: Configure Azure Key Vaults to use private DNS zones'
    definitionId: 'ac673a9a-f77d-4846-b2d8-a57f8e1c01d4'
    zoneId: dnsZoneIds.keyVault
  }
]

// Diagnostic settings to log-management for the resource types the archetype deploys.
var diagnosticsPolicies = [
  {
    name: 'alzl-diag-appservice'
    displayName: 'ALZ-lite: Enable logging by category group for App Service to Log Analytics'
    definitionId: 'c0d8e23a-47be-4032-961f-8b0ff3957061'
    roles: [logAnalyticsContributor]
  }
  {
    name: 'alzl-diag-sqlmi'
    displayName: 'ALZ-lite: Enable logging by category group for SQL managed instances to Log Analytics'
    definitionId: '8fc4ca5f-6abc-4b30-9565-0bd91ac49420'
    roles: [logAnalyticsContributor]
  }
  {
    name: 'alzl-diag-keyvault'
    displayName: 'ALZ-lite: Enable logging by category group for Key vaults to Log Analytics'
    definitionId: '6b359d8f-f88d-4052-aa7c-32015963ecc1'
    roles: [logAnalyticsContributor]
  }
  {
    name: 'alzl-diag-servicebus'
    displayName: 'ALZ-lite: Enable logging by category group for Service Bus Namespaces to Log Analytics'
    definitionId: '0277b2d5-6e6f-4d97-9929-a5c4eab56fd7'
    roles: [logAnalyticsContributor]
  }
  {
    name: 'alzl-diag-acr'
    displayName: 'ALZ-lite: Enable logging by category group for Container registries to Log Analytics'
    definitionId: '56288eb2-4350-461d-9ece-2bb242269dce'
    roles: [logAnalyticsContributor]
  }
  {
    name: 'alzl-diag-appinsights'
    displayName: 'ALZ-lite: Enable logging by category group for Application Insights to Log Analytics'
    definitionId: '79494980-ea12-4ca1-8cca-317e942b6da2'
    roles: [logAnalyticsContributor]
  }
  {
    name: 'alzl-diag-blob'
    displayName: 'ALZ-lite: Configure diagnostic settings for Blob Services to Log Analytics workspace'
    definitionId: 'b4fe1a3b-0715-4c6c-a5ea-ffc33cf823cb'
    roles: [logAnalyticsContributor, monitoringContributor]
  }
]

resource coreAssignments 'Microsoft.Authorization/policyAssignments@2025-03-01' = [
  for policy in corePolicies: {
    name: policy.name
    properties: {
      displayName: policy.displayName
      policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', policy.definitionId)
      parameters: policy.parameters
    }
  }
]

resource dnsAssignments 'Microsoft.Authorization/policyAssignments@2025-03-01' = [
  for policy in dnsPolicies: {
    name: policy.name
    location: location
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      displayName: policy.displayName
      policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', policy.definitionId)
      parameters: {
        privateDnsZoneId: {
          value: policy.zoneId
        }
      }
    }
  }
]

resource diagnosticsAssignments 'Microsoft.Authorization/policyAssignments@2025-03-01' = [
  for policy in diagnosticsPolicies: {
    name: policy.name
    location: location
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      displayName: policy.displayName
      policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', policy.definitionId)
      parameters: {
        logAnalytics: {
          value: logAnalyticsWorkspaceId
        }
      }
    }
  }
]

// Roles at mg-factory-corp, where the private endpoints and the diagnosed resources live.
resource dnsRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (policy, i) in dnsPolicies: {
    name: guid(managementGroup().id, policy.name, networkContributor)
    properties: {
      principalId: dnsAssignments[i].identity.principalId
      principalType: 'ServicePrincipal'
      roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', networkContributor)
    }
  }
]

var diagnosticsRoleList = flatten(map(
  range(0, length(diagnosticsPolicies)),
  i => map(diagnosticsPolicies[i].roles, role => { index: i, role: role })
))

resource diagnosticsRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for item in diagnosticsRoleList: {
    name: guid(managementGroup().id, diagnosticsPolicies[item.index].name, item.role)
    properties: {
      principalId: diagnosticsAssignments[item.index].identity.principalId
      principalType: 'ServicePrincipal'
      roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', item.role)
    }
  }
]

output dnsIdentities array = [
  for (policy, i) in dnsPolicies: {
    name: policy.name
    principalId: dnsAssignments[i].identity.principalId
    roleDefinitionId: networkContributor
  }
]

output diagnosticsIdentities array = [
  for (policy, i) in diagnosticsPolicies: {
    name: policy.name
    principalId: diagnosticsAssignments[i].identity.principalId
    roleDefinitionId: logAnalyticsContributor
  }
]
