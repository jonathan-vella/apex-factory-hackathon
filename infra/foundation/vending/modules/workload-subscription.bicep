// The workload subscription: rg-spoke with the spoke, Owner for the member, the budget and
// Defender for Cloud on Foundational CSPM only.
targetScope = 'subscription'

param location string
param memberIndex int
param hubVnetId string
param firewallPrivateIp string
param logAnalyticsWorkspaceId string
param memberPrincipalId string
param budgetAmount int
param budgetEmail string
param budgetStartDate string
param setDefenderFoundationalOnly bool
param miNetworkExists bool

var ownerRole = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'

resource spokeRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-spoke'
  location: location
}

module spoke 'spoke.bicep' = {
  scope: spokeRg
  name: 'vending-spoke-${memberIndex}'
  params: {
    location: location
    memberIndex: memberIndex
    hubVnetId: hubVnetId
    firewallPrivateIp: firewallPrivateIp
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    miNetworkExists: miNetworkExists
  }
}

resource memberOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(memberPrincipalId)) {
  name: guid(subscription().id, memberPrincipalId, ownerRole)
  properties: {
    principalId: memberPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', ownerRole)
  }
}

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: 'budget-factory-workload'
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
    }
    notifications: {
      actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [
          budgetEmail
        ]
      }
    }
  }
}

module defender '../../modules/defender-foundational.bicep' = if (setDefenderFoundationalOnly) {
  name: 'vending-defender-${memberIndex}'
}

output spokeVnetId string = spoke.outputs.vnetId
