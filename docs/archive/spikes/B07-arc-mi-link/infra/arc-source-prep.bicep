// B07 spike: prepares vm-app01 for MI link through an Arc run command (VM run commands stop working after Arc onboarding).
// Deploy into rg-datacenter after vm-app01 is Arc-enabled: the Windows Firewall rule for 5022 and the source database prep.
targetScope = 'resourceGroup'

@description('Region of the Arc machine resource.')
param location string = resourceGroup().location

@description('Member index n, 1-20. The MI subnet is 10.20.n.128/26.')
@minValue(1)
@maxValue(20)
param memberIndex int = 1

@description('Name of the Arc machine.')
param machineName string = 'vm-app01'

resource machine 'Microsoft.HybridCompute/machines@2025-01-13' existing = {
  name: machineName
}

resource sourcePrep 'Microsoft.HybridCompute/machines/runCommands@2025-01-13' = {
  parent: machine
  name: 'milink-source-prep'
  location: location
  properties: {
    source: {
      script: loadTextContent('../scripts/Prepare-MiLinkSource.ps1')
    }
    parameters: [
      {
        name: 'MiSubnetPrefix'
        value: '10.20.${memberIndex}.128/26'
      }
    ]
    asyncExecution: false
    timeoutInSeconds: 3600
  }
}

output executionState string = sourcePrep.properties.instanceView.executionState
