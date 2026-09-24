// vm-dev01 configuration: run commands that execute in order, each downloading its script from scriptsBaseUrl.
// Build Tools and SSMS share the Visual Studio installer, so they can't run in parallel.

@description('Azure region.')
param location string

@description('Name of the dev VM.')
param vmName string

@description('Base URL of infra/datacenter/scripts at a git ref.')
param scriptsBaseUrl string

resource vm 'Microsoft.Compute/virtualMachines@2025-11-01' existing = {
  name: vmName
}

resource tools 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'dev-01-tools'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Install-DevTools.ps1'
    }
    asyncExecution: false
    timeoutInSeconds: 3600
    treatFailureAsDeploymentFailure: true
  }
}

resource buildTools 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'dev-02-build-tools'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Install-DevBuildTools.ps1'
    }
    asyncExecution: false
    timeoutInSeconds: 3600
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    tools
  ]
}

resource ssms 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'dev-03-ssms'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Install-DevSsms.ps1'
    }
    asyncExecution: false
    timeoutInSeconds: 3600
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    buildTools
  ]
}

resource firstLogon 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'dev-04-first-logon'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Register-DevFirstLogon.ps1'
    }
    parameters: [
      {
        name: 'ScriptsBaseUrl'
        value: scriptsBaseUrl
      }
    ]
    asyncExecution: false
    timeoutInSeconds: 600
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    ssms
  ]
}

resource versions 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'dev-05-versions'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Write-DevVersions.ps1'
    }
    asyncExecution: false
    timeoutInSeconds: 600
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    firstLogon
  ]
}
