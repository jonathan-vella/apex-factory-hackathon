<#
.SYNOPSIS
Checks DNS and ports from inside a datacenter VM, through the hub.
.DESCRIPTION
Sent by scripts/Test-Connectivity.ps1 through a VM run command, or an Arc run command when vm-app01
is Arc-enabled (Windows PowerShell 5.1, as SYSTEM). Prints one line per check:
LABCHECK|PASS or FAIL|check|detail. Changes nothing.
.PARAMETER Role
dev for vm-dev01, app for vm-app01.
.PARAMETER FirewallIp
Private IP of afw-hub, the VNet's DNS server (DNS proxy).
.PARAMETER Zones
Comma-separated privatelink zones that must resolve through the firewall to the central private zones.
.PARAMETER Endpoints
dev only: comma-separated host:port pairs of the spoke's private endpoints, or none.
.PARAMETER PeSubnet
dev only: the CIDR the private endpoints must resolve into (snet-pe).
.PARAMETER AppVmIp
dev only: vm-app01's IP, which must answer on 80 and 1433.
.PARAMETER MiHost
app only: the SQL MI host name, or none.
.PARAMETER MiSubnet
app only: the CIDR the MI must resolve into (snet-sqlmi).
.EXAMPLE
.\Test-HubConnectivity.ps1 -Role dev -FirewallIp 10.100.0.4 -Zones privatelink.blob.core.windows.net -Endpoints none -PeSubnet 10.20.1.64/26 -AppVmIp 10.10.1.4
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('dev', 'app')]
    [string] $Role,
    [Parameter(Mandatory)]
    [string] $FirewallIp,
    [Parameter(Mandatory)]
    [string] $Zones,
    [string] $Endpoints = 'none',
    [string] $PeSubnet = 'none',
    [string] $AppVmIp = 'none',
    [string] $MiHost = 'none',
    [string] $MiSubnet = 'none'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Test-HubConnectivity.log'
# Script-scope copies: the checks run in script blocks.
$firewall = $FirewallIp
$peCidr = $PeSubnet
$appVm = $AppVmIp
$miCidr = $MiSubnet
$vmName = if ($Role -eq 'dev') { 'vm-dev01' } else { 'vm-app01' }

function Write-Check {
    param([string] $Check, [bool] $Pass, [string] $Detail)
    $status = if ($Pass) { 'PASS' } else { 'FAIL' }
    $line = "LABCHECK|$status|${vmName}: $Check|$Detail"
    Add-Content -Path $logFile -Value ('{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $line)
    Write-Output $line
}

function Invoke-Check {
    param([string] $Check, [scriptblock] $Test)
    try {
        $result = & $Test
        Write-Check -Check $Check -Pass $result[0] -Detail $result[1]
    }
    catch {
        Write-Check -Check $Check -Pass $false -Detail $_.Exception.Message
    }
}

function ConvertTo-UInt32 {
    param([string] $Address)
    $bytes = [Net.IPAddress]::Parse($Address).GetAddressBytes()
    [Array]::Reverse($bytes)
    return [BitConverter]::ToUInt32($bytes, 0)
}

function Test-InSubnet {
    param([string] $Address, [string] $Cidr)
    $network, $bits = $Cidr -split '/'
    $mask = if ([int] $bits -eq 0) { [uint32] 0 } else { [uint32] ([uint32]::MaxValue -shl (32 - [int] $bits)) }
    return ((ConvertTo-UInt32 $Address) -band $mask) -eq ((ConvertTo-UInt32 $network) -band $mask)
}

function Test-Tcp {
    param([string] $HostName, [int] $Port)
    $client = New-Object Net.Sockets.TcpClient
    try {
        $connect = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $connect.AsyncWaitHandle.WaitOne(5000)) {
            return $false
        }
        $client.EndConnect($connect)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}

function Resolve-PrivateAddress {
    param([string] $HostName)
    $records = Resolve-DnsName -Name $HostName -Type A -DnsOnly -QuickTimeout
    return @($records | Where-Object { $_.Type -eq 'A' } | ForEach-Object { $_.IPAddress })
}

# Hub DNS: the VM uses the firewall, and the firewall's DNS proxy answers for the central zones. An
# empty private zone's SOA looks like the public one, so the private endpoint checks below prove
# private resolution; Test-Connectivity.ps1 checks the zones' links to vnet-hub in Azure.
Invoke-Check -Check 'DNS server is the hub firewall' -Test {
    $servers = @(Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses } |
            ForEach-Object { $_.ServerAddresses })
    $pass = $servers -contains $firewall
    $detail = if ($pass) { 'configured' } else { "not yet: restart the VM or run ipconfig /renew. Servers: $($servers -join ', ')" }
    , @($pass, $detail)
}
foreach ($zone in ($Zones -split ',')) {
    Invoke-Check -Check "hub DNS proxy answers for $zone" -Test {
        $soa = Resolve-DnsName -Name $zone -Type SOA -Server $firewall -DnsOnly -QuickTimeout |
            Where-Object { $_.Type -eq 'SOA' } | Select-Object -First 1
        , @(($soa.PrimaryServer -eq 'azureprivatedns.net'), "SOA $($soa.PrimaryServer) from the firewall")
    }
}

if ($Role -eq 'dev') {
    if ($Endpoints -ne 'none') {
        foreach ($endpoint in ($Endpoints -split ',')) {
            $hostName, $port = $endpoint -split ':'
            Invoke-Check -Check "$hostName resolves into snet-pe" -Test {
                $addresses = Resolve-PrivateAddress -HostName $hostName
                $inside = @($addresses | Where-Object { Test-InSubnet -Address $_ -Cidr $peCidr })
                , @(($addresses.Count -gt 0 -and $inside.Count -eq $addresses.Count), "$($addresses.Count) address(es), $($inside.Count) in snet-pe")
            }
            Invoke-Check -Check "$hostName answers on $port" -Test {
                $open = Test-Tcp -HostName $hostName -Port ([int] $port)
                , @($open, $(if ($open) { 'connected' } else { 'no connection in 5 s' }))
            }
        }
    }
    foreach ($port in 80, 1433) {
        Invoke-Check -Check "vm-app01 answers on $port" -Test {
            $open = Test-Tcp -HostName $appVm -Port $port
            , @($open, $(if ($open) { 'connected' } else { 'no connection in 5 s' }))
        }
    }
    Invoke-Check -Check 'internet egress (NAT gateway)' -Test {
        $response = Invoke-WebRequest -Uri 'https://learn.microsoft.com' -UseBasicParsing -TimeoutSec 20 -MaximumRedirection 5
        , @(($response.StatusCode -eq 200), "HTTPS $($response.StatusCode)")
    }
}

if ($Role -eq 'app' -and $MiHost -ne 'none') {
    Invoke-Check -Check 'SQL MI resolves into snet-sqlmi' -Test {
        $addresses = Resolve-PrivateAddress -HostName $MiHost
        $inside = @($addresses | Where-Object { Test-InSubnet -Address $_ -Cidr $miCidr })
        , @(($addresses.Count -gt 0 -and $inside.Count -eq $addresses.Count), "$($addresses.Count) address(es), $($inside.Count) in snet-sqlmi")
    }
    foreach ($port in 5022, 11000) {
        Invoke-Check -Check "SQL MI answers on $port" -Test {
            $open = Test-Tcp -HostName $MiHost -Port $port
            , @($open, $(if ($open) { 'connected' } else { 'no connection in 5 s' }))
        }
    }
}
