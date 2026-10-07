// id-sqlmi-directory: the team's identity that SQL Managed Instances use as their primary identity,
// so they can look up Microsoft Entra principals (CREATE USER ... FROM EXTERNAL PROVIDER).
// It gets Microsoft Graph read permissions once, from scripts/Grant-SqlMiDirectoryRead.ps1.
targetScope = 'resourceGroup'

param location string

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'id-sqlmi-directory'
  location: location
}

output identityId string = identity.id
output principalId string = identity.properties.principalId
