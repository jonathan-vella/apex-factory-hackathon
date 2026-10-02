using 'main.bicep'

// Deploy with scripts/Deploy-AlzLite.ps1, which passes sharedSubscriptionId from its parameter.
param location = 'swedencentral'
param mgPrefix = 'mg-factory'
param sharedSubscriptionId = '00000000-0000-0000-0000-000000000000'
param additionalAllowedLocations = []
param setDefenderFoundationalOnly = true
