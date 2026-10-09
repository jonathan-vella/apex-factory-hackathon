// Microsoft Defender for Cloud on Foundational CSPM (free): every paid plan off.
// Deprecated plans (Dns, ContainerRegistry, KubernetesService) are already free and can't be set.
targetScope = 'subscription'

var paidPlans = [
  'VirtualMachines'
  'SqlServers'
  'AppServices'
  'StorageAccounts'
  'SqlServerVirtualMachines'
  'KeyVaults'
  'Arm'
  'OpenSourceRelationalDatabases'
  'CosmosDbs'
  'Containers'
  'CloudPosture'
  'Api'
  'AI'
]

@batchSize(1)
resource pricings 'Microsoft.Security/pricings@2024-01-01' = [
  for plan in paidPlans: {
    name: plan
    properties: {
      pricingTier: 'Free'
    }
  }
]
