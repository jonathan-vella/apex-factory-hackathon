// The member's "on-premises" datacenter: rg-datacenter with vm-app01, vm-dev01, NAT gateway and Bastion Developer.
// Deploy it with scripts/Deploy-Datacenter.ps1, which generates the passwords.
targetScope = 'subscription'

@description('Azure region. Fallback: germanywestcentral.')
param location string = 'swedencentral'

@description('Member index n, 1-20. The datacenter uses 10.10.n.0/24.')
@minValue(1)
@maxValue(20)
param memberIndex int = 1

@description('Size of both VMs. A v7 or other Gen2 size needs no other change.')
param vmSize string = 'Standard_D8as_v6'

@description('Windows 11 Enterprise image SKU for vm-dev01.')
param devImageSku string = 'win11-25h2-ent'

@description('Azure Hybrid Benefit for Windows Server on vm-app01. Assumes eligible licences. vm-dev01 always uses Windows_Client.')
param enableHybridBenefit bool = true

@description('Password of the labadmin user on both VMs.')
@secure()
param adminPassword string

@description('Password of the contosoapp SQL login.')
@secure()
param sqlAppPassword string

@description('Base URL of infra/datacenter/scripts at a git ref, as raw files.')
param scriptsBaseUrl string = 'https://raw.githubusercontent.com/jonathan-vella/apex-factory-hackathon/main/infra/datacenter/scripts'

@description('Passed to every run command. A new value makes Azure re-run them all, which a re-deploy needs to converge.')
param configRunId string = utcNow()

var adminUsername = 'labadmin'
var appVmName = 'vm-app01'
var devVmName = 'vm-dev01'
var appVmIp = '10.10.${memberIndex}.4'
var devVmIp = '10.10.${memberIndex}.5'
var packageUrl = 'https://github.com/jonathan-vella/apex-factory-hackathon/releases/download/legacy-v1/ContosoUniversity-legacy.zip'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-datacenter'
  location: location
}

module network 'modules/network.bicep' = {
  scope: rg
  name: 'datacenter-network'
  params: {
    location: location
    memberIndex: memberIndex
  }
}

module appVm 'modules/vm.bicep' = {
  scope: rg
  name: 'datacenter-vm-app01'
  params: {
    name: appVmName
    location: location
    vmSize: vmSize
    subnetId: network.outputs.subnetId
    privateIp: appVmIp
    imageReference: {
      publisher: 'MicrosoftSQLServer'
      offer: 'sql2022-ws2022'
      sku: 'sqldev-gen2'
      version: 'latest'
    }
    licenseType: enableHybridBenefit ? 'Windows_Server' : 'None'
    adminUsername: adminUsername
    adminPassword: adminPassword
    dataDiskSizeGB: 1024
  }
}

module devVm 'modules/vm.bicep' = {
  scope: rg
  name: 'datacenter-vm-dev01'
  params: {
    name: devVmName
    location: location
    vmSize: vmSize
    subnetId: network.outputs.subnetId
    privateIp: devVmIp
    imageReference: {
      publisher: 'MicrosoftWindowsDesktop'
      offer: 'windows-11'
      sku: devImageSku
      version: 'latest'
    }
    licenseType: 'Windows_Client'
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

module appConfig 'modules/app-vm-config.bicep' = {
  scope: rg
  name: 'datacenter-config-app01'
  params: {
    location: location
    vmName: appVm.outputs.name
    scriptsBaseUrl: scriptsBaseUrl
    appVmIp: appVmIp
    packageUrl: packageUrl
    adminUsername: adminUsername
    sqlAppPassword: sqlAppPassword
    adminPassword: adminPassword
    runId: configRunId
  }
}

module devConfig 'modules/dev-vm-config.bicep' = {
  scope: rg
  name: 'datacenter-config-dev01'
  params: {
    location: location
    vmName: devVm.outputs.name
    scriptsBaseUrl: scriptsBaseUrl
    adminUsername: adminUsername
    adminPassword: adminPassword
    runId: configRunId
  }
}

output resourceGroupName string = rg.name
output appVmName string = appVm.outputs.name
output appVmPrivateIp string = appVm.outputs.privateIp
output devVmName string = devVm.outputs.name
output devVmPrivateIp string = devVm.outputs.privateIp
output bastionName string = network.outputs.bastionName
