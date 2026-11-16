// afwp-hub: Azure Firewall Standard policy with DNS proxy and SNAT private ranges.
// Only snet-pe (.64/26 in each spoke) is left out of the SNAT private ranges, so the firewall SNATs
// network-rule traffic to private endpoints (flow symmetry) and keeps the real source IP elsewhere.
param location string
param name string = 'afwp-hub'
param extraSnatPrefixes array = []

var baseSnatRanges = [
  '10.10.0.0/16'
  '10.128.0.0/10'
  '10.100.0.0/16'
  '172.16.0.0/12'
  '192.168.0.0/16'
  '100.64.0.0/10'
]

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2025-09-01' = {
  name: name
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    dnsSettings: {
      enableProxy: true
    }
    snat: {
      privateRanges: union(baseSnatRanges, extraSnatPrefixes)
    }
  }
}

output id string = firewallPolicy.id
