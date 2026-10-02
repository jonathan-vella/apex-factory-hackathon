using 'main.bicep'

// Deploy with scripts/Deploy-Vending.ps1, which finds the hub's IDs in the shared services
// subscription and passes them, the subscriptions and the member's values.
param location = 'swedencentral'
param memberIndex = 1
param mgPrefix = 'mg-factory'
param workloadSubscriptionId = '00000000-0000-0000-0000-000000000000'
param sharedSubscriptionId = '00000000-0000-0000-0000-000000000000'
param hubVnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub'
param firewallPrivateIp = '10.100.0.4'
param firewallPolicyId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/firewallPolicies/afwp-hub'
param dnsZoneResourceGroupId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub'
param logAnalyticsWorkspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/log-management'
param memberPrincipalId = ''
param budgetAmount = 500
param budgetEmail = 'platform-lead@example.com'
param connectDatacenter = false
param setDefenderFoundationalOnly = true
param miNetworkExists = false
