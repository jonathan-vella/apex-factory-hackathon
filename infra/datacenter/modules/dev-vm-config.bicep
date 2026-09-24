// vm-dev01 configuration: run commands that execute in order, each downloading its script from scriptsBaseUrl.
// Build Tools and SSMS share the Visual Studio installer, so they can't run in parallel.

@description('Azure region.')
param location string

@description('Name of the dev VM.')
param vmName string

@description('Base URL of infra/datacenter/scripts at a git ref.')
param scriptsBaseUrl string

@description('Local admin user name.')
param adminUsername string

@description('Password of the local admin user.')
@secure()
param adminPassword string

@description('Changes on every deployment, so Azure re-runs every run command. The scripts skip finished work.')
param runId string

var runIdParameter = {
  name: 'RunId'
  value: runId
}

resource vm 'Microsoft.Compute/virtualMachines@2025-11-01' existing = {
  name: vmName
}

// ARM sets osProfile.adminPassword only at creation, so this converges an existing VM to the deployed password.
resource adminPasswordCommand 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'dev-00-admin-password'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Set-LabAdminPassword.ps1'
    }
    parameters: [
      runIdParameter
      {
        name: 'AdminUsername'
        value: adminUsername
      }
    ]
    protectedParameters: [
      {
        name: 'AdminPassword'
        value: adminPassword
      }
    ]
    asyncExecution: false
    timeoutInSeconds: 300
    treatFailureAsDeploymentFailure: true
  }
}

resource tools 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'dev-01-tools'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Install-DevTools.ps1'
    }
    parameters: [
      runIdParameter
    ]
    asyncExecution: false
    timeoutInSeconds: 3600
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    adminPasswordCommand
  ]
}

resource buildTools 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'dev-02-build-tools'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Install-DevBuildTools.ps1'
    }
    parameters: [
      runIdParameter
    ]
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
    parameters: [
      runIdParameter
    ]
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
      runIdParameter
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
    parameters: [
      runIdParameter
    ]
    asyncExecution: false
    timeoutInSeconds: 600
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    firstLogon
  ]
}
