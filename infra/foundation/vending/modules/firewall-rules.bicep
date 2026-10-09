// Member n's rule collection group in afwp-hub. It allows only what the kit needs; everything else
// between the datacenter, the spoke and the internet through the firewall is denied.
param firewallPolicyName string
param memberIndex int

var devVmIp = '10.10.${memberIndex}.5'
var sqlServerIp = '10.10.${memberIndex}.4'
var appPrefix = '10.20.${memberIndex}.0/26'
var pePrefix = '10.20.${memberIndex}.64/26'
var miPrefix = '10.20.${memberIndex}.128/26'

// Application Insights ingestion and Live Metrics, from
// https://learn.microsoft.com/azure/azure-monitor/fundamentals/azure-monitor-network-access (2026-10-02).
var azureMonitorFqdns = [
  'dc.applicationinsights.azure.com'
  'dc.applicationinsights.microsoft.com'
  'dc.services.visualstudio.com'
  '*.in.applicationinsights.azure.com'
  'live.applicationinsights.azure.com'
  'rt.applicationinsights.microsoft.com'
  'rt.services.visualstudio.com'
  '*.livediagnostics.monitor.azure.com'
]

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2025-09-01' existing = {
  name: firewallPolicyName
}

resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2025-09-01' = {
  parent: firewallPolicy
  name: 'rcg-member-${memberIndex}'
  properties: {
    priority: 1000 + memberIndex
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'net-member-${memberIndex}'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'dev-to-private-endpoints'
            ipProtocols: ['TCP']
            sourceAddresses: [devVmIp]
            destinationAddresses: [pePrefix]
            destinationPorts: ['443', '5671']
          }
          {
            ruleType: 'NetworkRule'
            name: 'dev-to-app'
            ipProtocols: ['TCP']
            sourceAddresses: [devVmIp]
            destinationAddresses: [appPrefix]
            destinationPorts: ['443']
          }
          {
            ruleType: 'NetworkRule'
            name: 'dev-to-sqlmi'
            ipProtocols: ['TCP']
            sourceAddresses: [devVmIp]
            destinationAddresses: [miPrefix]
            destinationPorts: ['1433', '11000-11999']
          }
          {
            ruleType: 'NetworkRule'
            name: 'milink-sqlserver-to-mi'
            ipProtocols: ['TCP']
            sourceAddresses: [sqlServerIp]
            destinationAddresses: [miPrefix]
            destinationPorts: ['5022', '11000-11999']
          }
          {
            ruleType: 'NetworkRule'
            name: 'milink-mi-to-sqlserver'
            ipProtocols: ['TCP']
            sourceAddresses: [miPrefix]
            destinationAddresses: [sqlServerIp]
            destinationPorts: ['5022']
          }
          {
            ruleType: 'NetworkRule'
            name: 'app-to-entra-id'
            ipProtocols: ['TCP']
            sourceAddresses: [appPrefix]
            destinationAddresses: ['AzureActiveDirectory']
            destinationPorts: ['443']
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'app-member-${memberIndex}'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'app-to-mcr'
            sourceAddresses: [appPrefix]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              'mcr.microsoft.com'
              '*.data.mcr.microsoft.com'
            ]
          }
          {
            ruleType: 'ApplicationRule'
            name: 'app-to-azure-monitor'
            sourceAddresses: [appPrefix]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: azureMonitorFqdns
          }
        ]
      }
    ]
  }
}
