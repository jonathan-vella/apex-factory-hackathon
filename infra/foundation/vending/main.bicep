// Vending: places one member's workload subscription under mg-factory-corp and connects it to the
// team's hub: spoke, peering, UDRs, DNS, firewall rules, RBAC, budget and Defender on Foundational CSPM.
// Deploy it at the Tenant Root management group with scripts/Deploy-Vending.ps1, which finds the hub.
// Zones: none set. Nothing here has a zone or a public IP.
targetScope = 'managementGroup'

@description('Azure region. Fallback: germanywestcentral.')
param location string = 'swedencentral'

@description('Member index n, 1-20. The spoke uses 10.20.n.0/24 and the datacenter 10.10.n.0/24.')
@minValue(1)
@maxValue(20)
param memberIndex int = 1

@description('Prefix of the kit\'s management groups.')
param mgPrefix string = 'mg-factory'

@description('The member\'s workload subscription.')
@minLength(36)
@maxLength(36)
param workloadSubscriptionId string

@description('The team\'s shared services subscription, which holds the hub.')
@minLength(36)
@maxLength(36)
param sharedSubscriptionId string

@description('Resource ID of vnet-hub.')
param hubVnetId string

@description('Private IP of afw-hub: the spoke\'s and the datacenter\'s DNS server and next hop.')
param firewallPrivateIp string

@description('Resource ID of afwp-hub.')
param firewallPolicyId string

@description('Resource ID of the resource group that holds the central privatelink zones (rg-hub).')
param dnsZoneResourceGroupId string

@description('Resource ID of log-management.')
param logAnalyticsWorkspaceId string

@description('Object ID of the member, who gets Owner on the workload subscription. Empty: skipped.')
param memberPrincipalId string = ''

@description('Monthly budget on the workload subscription, in the billing currency.')
@minValue(1)
param budgetAmount int = 500

@description('Email address for the budget alert at 80%.')
param budgetEmail string

@description('First day of the budget\'s first month, yyyy-MM-dd. Keep an existing budget\'s start date on re-runs.')
param budgetStartDate string = utcNow('yyyy-MM-01')

@description('Peer vnet-datacenter with the hub and point it at the hub. Set when rg-datacenter exists.')
param connectDatacenter bool = false

@description('Microsoft Defender for Cloud on Foundational CSPM only: every paid plan off.')
param setDefenderFoundationalOnly bool = true

@description('nsg-sqlmi and rt-sqlmi already exist in rg-spoke (a re-run): leave them, and the rules and routes SQL MI adds, alone.')
param miNetworkExists bool = false

var hubVnetParts = split(hubVnetId, '/')
var hubResourceGroup = hubVnetParts[4]
var hubVnetName = hubVnetParts[8]
var firewallPolicyParts = split(firewallPolicyId, '/')

resource corpMg 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  scope: tenant()
  name: '${mgPrefix}-corp'
}

resource workloadPlacement 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = {
  parent: corpMg
  name: workloadSubscriptionId
}

module workload 'modules/workload-subscription.bicep' = {
  scope: subscription(workloadSubscriptionId)
  name: 'vending-workload-${memberIndex}'
  params: {
    location: location
    memberIndex: memberIndex
    hubVnetId: hubVnetId
    firewallPrivateIp: firewallPrivateIp
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    memberPrincipalId: memberPrincipalId
    budgetAmount: budgetAmount
    budgetEmail: budgetEmail
    budgetStartDate: budgetStartDate
    setDefenderFoundationalOnly: setDefenderFoundationalOnly
    miNetworkExists: miNetworkExists
  }
  dependsOn: [
    workloadPlacement
  ]
}

module hubPeerings 'modules/hub-peerings.bicep' = {
  scope: resourceGroup(sharedSubscriptionId, hubResourceGroup)
  name: 'vending-hub-peerings-${memberIndex}'
  params: {
    hubVnetName: hubVnetName
    memberIndex: memberIndex
    spokeVnetId: workload.outputs.spokeVnetId
    datacenterVnetId: connectDatacenter
      ? '/subscriptions/${workloadSubscriptionId}/resourceGroups/rg-datacenter/providers/Microsoft.Network/virtualNetworks/vnet-datacenter'
      : ''
  }
}

module firewallRules 'modules/firewall-rules.bicep' = {
  scope: resourceGroup(sharedSubscriptionId, firewallPolicyParts[4])
  name: 'vending-firewall-rules-${memberIndex}'
  params: {
    firewallPolicyName: firewallPolicyParts[8]
    memberIndex: memberIndex
  }
}

// Peering first, then the UDR, then the DNS servers: VMs keep name resolution throughout.
module datacenter 'modules/datacenter-connection.bicep' = if (connectDatacenter) {
  scope: resourceGroup(workloadSubscriptionId, 'rg-datacenter')
  name: 'vending-datacenter-${memberIndex}'
  params: {
    location: location
    memberIndex: memberIndex
    hubVnetId: hubVnetId
    firewallPrivateIp: firewallPrivateIp
  }
  dependsOn: [
    hubPeerings
    firewallRules
  ]
}

output managementGroup string = corpMg.name
output spokeVnetId string = workload.outputs.spokeVnetId
output dnsZoneResourceGroupId string = dnsZoneResourceGroupId
output datacenterConnected bool = connectDatacenter
