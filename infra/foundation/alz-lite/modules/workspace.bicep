// log-management: the team's central Log Analytics workspace.
param location string

resource workspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: 'log-management'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output workspaceId string = workspace.id
