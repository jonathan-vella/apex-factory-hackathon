// vm-app01 configuration: run commands that execute in order, each downloading its script from scriptsBaseUrl.

@description('Azure region.')
param location string

@description('Name of the app VM.')
param vmName string

@description('Base URL of infra/datacenter/scripts at a git ref.')
param scriptsBaseUrl string

@description('Private IP of the app VM, used in the app connection string.')
param appVmIp string

@description('Download URL of ContosoUniversity-legacy.zip.')
param packageUrl string

@description('Local admin user name, made a SQL Server sysadmin.')
param adminUsername string

@description('Password of the contosoapp SQL login.')
@secure()
param sqlAppPassword string

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
  name: 'app-00-admin-password'
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

resource dataDisk 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'app-01-data-disk'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Initialize-AppDataDisk.ps1'
    }
    parameters: [
      runIdParameter
    ]
    asyncExecution: false
    timeoutInSeconds: 900
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    adminPasswordCommand
  ]
}

resource sqlServer 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'app-02-sql-server'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Set-AppSqlServer.ps1'
    }
    parameters: [
      runIdParameter
      {
        name: 'AdminUsername'
        value: adminUsername
      }
    ]
    asyncExecution: false
    timeoutInSeconds: 1200
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    dataDisk
  ]
}

resource database 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'app-03-database'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/New-AppDatabase.ps1'
    }
    parameters: [
      runIdParameter
    ]
    protectedParameters: [
      {
        name: 'SqlAppPassword'
        value: sqlAppPassword
      }
    ]
    asyncExecution: false
    timeoutInSeconds: 900
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    sqlServer
  ]
}

resource webFeatures 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'app-04-web-features'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Install-AppWebFeatures.ps1'
    }
    parameters: [
      runIdParameter
    ]
    asyncExecution: false
    timeoutInSeconds: 1800
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    database
  ]
}

resource legacySite 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'app-05-legacy-site'
  location: location
  properties: {
    source: {
      scriptUri: '${scriptsBaseUrl}/Install-AppLegacySite.ps1'
    }
    parameters: [
      runIdParameter
      {
        name: 'AppVmIp'
        value: appVmIp
      }
      {
        name: 'PackageUrl'
        value: packageUrl
      }
    ]
    protectedParameters: [
      {
        name: 'SqlAppPassword'
        value: sqlAppPassword
      }
    ]
    asyncExecution: false
    timeoutInSeconds: 1800
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    webFeatures
  ]
}
