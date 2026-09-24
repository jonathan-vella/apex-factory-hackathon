// One datacenter VM: NIC with a static private IP, Trusted Launch, Premium SSD disks, no public IP, no zone.

@description('VM name, also used for its NIC and disk names.')
param name string

@description('Azure region.')
param location string

@description('VM size.')
param vmSize string

@description('Resource ID of snet-servers.')
param subnetId string

@description('Static private IP address.')
param privateIp string

@description('Marketplace image reference (publisher, offer, sku, version).')
param imageReference object

@description('Windows_Server, Windows_Client or None.')
@allowed([
  'Windows_Server'
  'Windows_Client'
  'None'
])
param licenseType string

@description('Local admin user name.')
param adminUsername string

@description('Local admin password.')
@secure()
param adminPassword string

@description('Size of the data disk at LUN 0 in GiB. 0 means no data disk.')
param dataDiskSizeGB int = 0

resource nic 'Microsoft.Network/networkInterfaces@2025-09-01' = {
  name: 'nic-${name}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: privateIp
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2025-11-01' = {
  name: name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    licenseType: licenseType
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    osProfile: {
      computerName: name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: 'osdisk-${name}'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: dataDiskSizeGB > 0
        ? [
            {
              name: 'disk-data-${name}'
              lun: 0
              createOption: 'Empty'
              diskSizeGB: dataDiskSizeGB
              caching: 'ReadOnly'
              managedDisk: {
                storageAccountType: 'Premium_LRS'
              }
            }
          ]
        : []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

output name string = vm.name
output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
