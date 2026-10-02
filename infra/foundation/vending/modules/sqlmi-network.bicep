// nsg-sqlmi and rt-sqlmi, created empty and only once: SQL MI's network intent policy adds its own
// rules and routes, and a later PUT without them would remove them. The kit's rules and routes are
// child resources in spoke.bicep.
param location string

resource miNsg 'Microsoft.Network/networkSecurityGroups@2025-09-01' = {
  name: 'nsg-sqlmi'
  location: location
}

resource miRouteTable 'Microsoft.Network/routeTables@2025-09-01' = {
  name: 'rt-sqlmi'
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}
