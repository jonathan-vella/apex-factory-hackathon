@description('SQL managed instance name (lowercase, globally unique).')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Resource ID of the vended, MI-delegated subnet (snet-sqlmi). Never declared or modified here.')
param subnetId string

@description('Entra tenant ID for the administrator.')
param tenantId string

@description('Entra administrator login (deployer UPN).')
param adminLogin string

@description('Entra administrator object ID (deployer).')
param adminObjectId string

@description('Windows time zone ID of the start/stop schedule.')
param scheduleTimeZoneId string

@description('Schedule start time (HH:mm).')
param scheduleStartTime string

@description('Schedule stop time (HH:mm).')
param scheduleStopTime string

@description('Days on which the instance starts and stops.')
param scheduleDays array

// Azure Hybrid Benefit is the default (ADR-0005). To pay the licence-included rate instead, set this to 'LicenseIncluded'; see the project README.
var licenseType = 'BasePrice'

// Raw Bicep: AVM sql/managed-instance 0.5.1 has no databaseFormat. Entra-only, no SQL login, no public data endpoint.
resource sqlManagedInstance 'Microsoft.Sql/managedInstances@2025-01-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 4
  }
  properties: {
    subnetId: subnetId
    vCores: 4
    storageSizeInGB: 64
    licenseType: licenseType
    requestedBackupStorageRedundancy: 'Local'
    databaseFormat: 'SQLServer2022'
    zoneRedundant: false
    isGeneralPurposeV2: false
    publicDataEndpointEnabled: false
    minimalTlsVersion: '1.2'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: adminLogin
      sid: adminObjectId
      tenantId: tenantId
      azureADOnlyAuthentication: true
    }
  }
}

// Takes effect only after the MI link is removed (ADR-0008); the link blocks stop.
resource startStopSchedule 'Microsoft.Sql/managedInstances/startStopSchedules@2025-01-01' = {
  parent: sqlManagedInstance
  name: 'default'
  properties: {
    timeZoneId: scheduleTimeZoneId
    scheduleList: [
      for day in scheduleDays: {
        startDay: day
        startTime: scheduleStartTime
        stopDay: day
        stopTime: scheduleStopTime
      }
    ]
  }
}

output name string = sqlManagedInstance.name
output fullyQualifiedDomainName string = sqlManagedInstance.properties.fullyQualifiedDomainName
