#Requires -Version 7.4

<#
.SYNOPSIS
Checks DNS and ports from inside the member's datacenter, through the team's hub.
.DESCRIPTION
Runs read-only checks after vending and reports PASS or FAIL per check, then a verdict.
In Azure: the datacenter and the spoke are peered with the hub, both use the firewall as DNS server,
and snet-servers keeps internet egress on the NAT gateway.
From vm-dev01 (VM run command): the firewall's DNS proxy answers from the central private DNS zones;
each private endpoint in the spoke resolves to a private IP in snet-pe and connects on its port;
vm-app01 (10.10.n.4) answers on 80 and 1433; internet egress works through the NAT gateway.
From vm-app01 (Arc run command once it's Arc-enabled, VM run command before): the same DNS checks
and, if a SQL MI exists in the spoke, that its host name resolves into snet-sqlmi and TCP 5022 and
11000 connect.
Only the checks that apply run: before the archetype exists there are no private endpoints or MI,
and the script says it skips those checks. Exits 0 when every check passes, 1 otherwise.
.PARAMETER SubscriptionId
The member's workload subscription.
.PARAMETER SharedSubscriptionId
The team's shared services subscription, which holds the hub.
.PARAMETER MemberIndex
The member index n, 1-20.
.EXAMPLE
./scripts/Test-Connectivity.ps1 -SubscriptionId '<workload-subscription-id>' -SharedSubscriptionId '<shared-services-subscription-id>' -MemberIndex 1
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Test-Connectivity.ps1 -SubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex $s.memberIndex
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SubscriptionId,
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SharedSubscriptionId,
    [ValidateRange(1, 20)]
    [int] $MemberIndex = 1
)

$ErrorActionPreference = 'Stop'
$workloadSubscription = $SubscriptionId
$datacenterRg = 'rg-datacenter'
$probeScript = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'infra', 'foundation', 'scripts', 'Test-HubConnectivity.ps1'
$zones = 'privatelink.blob.core.windows.net,privatelink.servicebus.windows.net,privatelink.azurecr.io,privatelink.vaultcore.azure.net'
$peSubnet = "10.20.$MemberIndex.64/26"
$miSubnet = "10.20.$MemberIndex.128/26"
$appVmIp = "10.10.$MemberIndex.4"
$arcApiVersion = '2025-01-13'
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param([string] $Check, [bool] $Pass, [string] $Detail)
    $results.Add([pscustomobject]@{
            Check = $Check
            Status = if ($Pass) { 'PASS' } else { 'FAIL' }
            Detail = $Detail
        })
}

function Invoke-AzureCli {
    param([string[]] $Arguments, [string] $Subscription = $workloadSubscription)
    # Capture native stderr rather than letting the CLI print subscription IDs.
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --subscription $Subscription --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE)."
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

function Get-OptionalResource {
    param([string[]] $Arguments, [string] $Subscription = $workloadSubscription)
    try {
        return Invoke-AzureCli -Arguments $Arguments -Subscription $Subscription
    }
    catch {
        return $null
    }
}

function Add-ProbeResult {
    param([string] $Name, [string] $Message)
    $lines = @($Message -split "`r?`n" | Where-Object { $_ -like 'LABCHECK|*' })
    if ($lines.Count -eq 0) {
        Add-Result -Check "${Name}: in-VM checks" -Pass $false -Detail "no results: $($Message.Trim() -replace '\s+', ' ')"
        return
    }
    foreach ($line in $lines) {
        $parts = $line -split '\|', 4
        Add-Result -Check $parts[2] -Pass ($parts[1] -eq 'PASS') -Detail $parts[3]
    }
}

function Invoke-VmProbe {
    param([string] $Name, [hashtable] $Parameters)
    $arguments = @('vm', 'run-command', 'invoke', '-g', $datacenterRg, '-n', $Name, '--command-id', 'RunPowerShellScript',
        '--scripts', "@$probeScript", '--parameters') + @($Parameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" })
    $response = Invoke-AzureCli -Arguments $arguments
    Add-ProbeResult -Name $Name -Message (($response.value | ForEach-Object { $_.message }) -join "`n")
}

# Arc run commands are resources: create one, wait for it, read its output, then delete it.
function Invoke-ArcProbe {
    param([string] $MachineId, [string] $Location, [hashtable] $Parameters)
    $uri = "https://management.azure.com$MachineId/runCommands/hub-connectivity-probe?api-version=$arcApiVersion"
    $body = @{
        location = $Location
        properties = @{
            source = @{ script = Get-Content -Path $probeScript -Raw }
            parameters = @($Parameters.GetEnumerator() | ForEach-Object { @{ name = $_.Key; value = [string] $_.Value } })
            asyncExecution = $false
            timeoutInSeconds = 900
        }
    }
    $bodyFile = Join-Path ([System.IO.Path]::GetTempPath()) "arc-probe-$([guid]::NewGuid()).json"
    try {
        $body | ConvertTo-Json -Depth 6 | Set-Content -Path $bodyFile -Encoding utf8NoBOM
        $null = Invoke-AzureCli -Arguments @('rest', '--method', 'put', '--uri', $uri, '--body', "@$bodyFile")
        $deadline = (Get-Date).AddMinutes(15)
        do {
            Start-Sleep -Seconds 15
            $command = Invoke-AzureCli -Arguments @('rest', '--method', 'get', '--uri', $uri)
            $state = $command.properties.provisioningState
        } while ($state -notin 'Succeeded', 'Failed', 'Canceled' -and (Get-Date) -lt $deadline)
        $view = $command.properties.instanceView
        Add-ProbeResult -Name 'vm-app01 (Arc)' -Message "$($view.output)`n$($view.error)"
    }
    finally {
        Remove-Item -Path $bodyFile -Force -ErrorAction SilentlyContinue
        $null = Get-OptionalResource -Arguments @('rest', '--method', 'delete', '--uri', $uri)
    }
}

function Test-Peering {
    param([string] $Check, [string] $ResourceGroup, [string] $VnetName, [string] $PeeringName, [string] $Subscription = $workloadSubscription)
    $peering = Get-OptionalResource -Subscription $Subscription -Arguments @('network', 'vnet', 'peering', 'show', '-g', $ResourceGroup, '--vnet-name', $VnetName, '-n', $PeeringName)
    $state = if ($peering) { $peering.peeringState } else { 'missing' }
    Add-Result -Check $Check -Pass ($state -eq 'Connected') -Detail $state
}

Write-Output "Checking member $MemberIndex's connectivity through the hub. The in-VM checks take a few minutes."

$firewall = Get-OptionalResource -Subscription $SharedSubscriptionId -Arguments @('resource', 'show', '-g', 'rg-hub', '-n', 'afw-hub', '--resource-type', 'Microsoft.Network/azureFirewalls')
if (-not $firewall) {
    Add-Result -Check 'azure: afw-hub exists' -Pass $false -Detail 'not found in the shared services subscription. Deploy ALZ-lite first.'
}
$datacenterVnet = Get-OptionalResource -Arguments @('network', 'vnet', 'show', '-g', $datacenterRg, '-n', 'vnet-datacenter')
if (-not $datacenterVnet) {
    Add-Result -Check 'azure: vnet-datacenter exists' -Pass $false -Detail 'not found. Deploy the datacenter, then vending.'
}
$spokeVnet = Get-OptionalResource -Arguments @('network', 'vnet', 'show', '-g', 'rg-spoke', '-n', 'vnet-spoke')
if (-not $spokeVnet) {
    Add-Result -Check 'azure: vnet-spoke exists' -Pass $false -Detail 'not found. Run scripts/Deploy-Vending.ps1.'
}

if ($results.Count -eq 0) {
    $firewallIp = $firewall.properties.ipConfigurations[0].properties.privateIPAddress

    # Azure side of the network contract.
    Test-Peering -Check 'azure: datacenter peered with the hub' -ResourceGroup $datacenterRg -VnetName 'vnet-datacenter' -PeeringName 'peer-datacenter-to-hub'
    Test-Peering -Check 'azure: spoke peered with the hub' -ResourceGroup 'rg-spoke' -VnetName 'vnet-spoke' -PeeringName 'peer-spoke-to-hub'
    foreach ($vnet in $datacenterVnet, $spokeVnet) {
        $servers = @($vnet.dhcpOptions.dnsServers)
        Add-Result -Check "azure: $($vnet.name) DNS is the hub firewall" -Pass ($servers.Count -eq 1 -and $servers[0] -eq $firewallIp) -Detail "$($servers.Count) DNS server(s)"
    }
    $subnet = Get-OptionalResource -Arguments @('network', 'vnet', 'subnet', 'show', '-g', $datacenterRg, '--vnet-name', 'vnet-datacenter', '-n', 'snet-servers')
    $natOk = $subnet -and $subnet.natGateway.id -match '/natGateways/nat-datacenter$'
    $routes = if ($subnet.routeTable) { @((Invoke-AzureCli -Arguments @('network', 'route-table', 'show', '--ids', $subnet.routeTable.id)).routes) } else { @() }
    $noDefaultRoute = -not ($routes | Where-Object addressPrefix -EQ '0.0.0.0/0')
    $spokeRoute = [bool] ($routes | Where-Object addressPrefix -EQ "10.20.$MemberIndex.0/24")
    Add-Result -Check 'azure: snet-servers egress on the NAT gateway' -Pass ($natOk -and $noDefaultRoute) -Detail "NAT gateway $(if ($natOk) { 'attached' } else { 'missing' }), default route $(if ($noDefaultRoute) { 'none' } else { 'present' })"
    Add-Result -Check 'azure: snet-servers sends the spoke to the firewall' -Pass $spokeRoute -Detail "$($routes.Count) route(s)"
    foreach ($zone in $zones -split ',') {
        $link = Get-OptionalResource -Subscription $SharedSubscriptionId -Arguments @('network', 'private-dns', 'link', 'vnet', 'show',
            '-g', 'rg-hub', '-z', $zone, '-n', 'link-vnet-hub')
        $linkState = if ($link) { $link.virtualNetworkLinkState } else { 'missing' }
        Add-Result -Check "azure: $zone linked to vnet-hub" -Pass ($linkState -eq 'Completed') -Detail $linkState
    }

    # What exists in the spoke decides which checks apply.
    $endpoints = [System.Collections.Generic.List[string]]::new()
    $privateEndpoints = @(Get-OptionalResource -Arguments @('network', 'private-endpoint', 'list') |
            Where-Object { $_.subnet.id -match '/resourceGroups/rg-spoke/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/snet-pe$' })
    foreach ($endpoint in $privateEndpoints) {
        foreach ($nicRef in $endpoint.networkInterfaces) {
            $nic = Invoke-AzureCli -Arguments @('network', 'nic', 'show', '--ids', $nicRef.id)
            foreach ($ipConfig in $nic.ipConfigurations) {
                $link = $ipConfig.privateLinkConnectionProperties
                $ports = if ($link.groupId -eq 'namespace') { 443, 5671 } else { , 443 }
                foreach ($fqdn in $link.fqdns) {
                    foreach ($port in $ports) {
                        $endpoints.Add("${fqdn}:$port")
                    }
                }
            }
        }
    }
    if ($endpoints.Count -eq 0) {
        Write-Output 'No private endpoints in snet-pe yet (the archetype adds them): skipping the private endpoint checks.'
    }
    $mi = @(Get-OptionalResource -Arguments @('sql', 'mi', 'list') |
            Where-Object { $_.subnetId -match '/resourceGroups/rg-spoke/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/snet-sqlmi$' }) |
        Select-Object -First 1
    if (-not $mi) {
        Write-Output 'No SQL MI in snet-sqlmi yet (the archetype adds it): skipping the MI checks from vm-app01.'
    }

    # vm-dev01, through a VM run command.
    $devVm = Get-OptionalResource -Arguments @('vm', 'show', '--show-details', '-g', $datacenterRg, '-n', 'vm-dev01')
    if ($devVm.powerState -ne 'VM running') {
        Add-Result -Check 'vm-dev01: running' -Pass $false -Detail "$($devVm.powerState). Start it and run this again."
    }
    else {
        try {
            Invoke-VmProbe -Name 'vm-dev01' -Parameters @{
                Role = 'dev'; FirewallIp = $firewallIp; Zones = $zones; PeSubnet = $peSubnet; AppVmIp = $appVmIp
                Endpoints = if ($endpoints.Count) { $endpoints -join ',' } else { 'none' }
            }
        }
        catch {
            Add-Result -Check 'vm-dev01: in-VM checks' -Pass $false -Detail $_.Exception.Message
        }
    }

    # vm-app01: an Arc run command once it's Arc-enabled (its Azure guest agent is off then).
    $appParameters = @{
        Role = 'app'; FirewallIp = $firewallIp; Zones = $zones; MiSubnet = $miSubnet
        MiHost = if ($mi) { $mi.fullyQualifiedDomainName } else { 'none' }
    }
    $arcMachine = Get-OptionalResource -Arguments @('resource', 'show', '-g', $datacenterRg, '-n', 'vm-app01', '--resource-type', 'Microsoft.HybridCompute/machines')
    try {
        if ($arcMachine -and $arcMachine.properties.status -eq 'Connected') {
            Invoke-ArcProbe -MachineId $arcMachine.id -Location $arcMachine.location -Parameters $appParameters
        }
        else {
            $appVm = Get-OptionalResource -Arguments @('vm', 'show', '--show-details', '-g', $datacenterRg, '-n', 'vm-app01')
            if ($appVm.powerState -ne 'VM running') {
                Add-Result -Check 'vm-app01: running' -Pass $false -Detail "$($appVm.powerState). Start it and run this again."
            }
            else {
                Invoke-VmProbe -Name 'vm-app01' -Parameters $appParameters
            }
        }
    }
    catch {
        Add-Result -Check 'vm-app01: in-VM checks' -Pass $false -Detail $_.Exception.Message
    }
}

$results | Format-Table Check, Status, Detail -Wrap | Out-String -Width 200 | Write-Output
$failures = @($results | Where-Object Status -EQ 'FAIL').Count
if ($failures -eq 0) {
    Write-Output "PASS: all $($results.Count) checks passed."
    exit 0
}
Write-Output "FAIL: $failures of $($results.Count) checks failed."
exit 1
