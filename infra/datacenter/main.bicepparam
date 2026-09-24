using './main.bicep'

// Defaults for the datacenter. No secrets: scripts/Deploy-Datacenter.ps1 generates the passwords
// and passes them, with these values, in a temporary parameters file.
param location = 'swedencentral'
param memberIndex = 1
param vmSize = 'Standard_D8as_v6'
param devImageSku = 'win11-25h2-ent'
param enableHybridBenefit = true
param scriptsBaseUrl = 'https://raw.githubusercontent.com/jonathan-vella/apex-factory-hackathon/main/infra/datacenter/scripts'
param adminPassword = ''
param sqlAppPassword = ''
