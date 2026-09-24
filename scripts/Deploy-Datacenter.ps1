#Requires -Version 7.4

<#
.SYNOPSIS
Deploys the member's "on-premises" datacenter into rg-datacenter.
.DESCRIPTION
Deploys infra/datacenter/main.bicep at subscription scope: vm-app01 (Windows Server 2022, IIS with the
legacy Contoso University, SQL Server 2022 Developer, MSMQ), vm-dev01 (Windows 11 Enterprise with the
developer tools), a private VNet with a NAT gateway for outbound traffic and Bastion Developer.
Nothing is reachable from the internet. The run takes up to 60 minutes and is unattended.

labadmin (both VMs) and the SQL login contosoapp use the fixed, documented lab password
FactoryLab-2026-Pw unless you pass -AdminPassword or -SqlAppPassword. The datacenter has no public IPs
and is reachable only through Bastion, so a documented lab password is acceptable here, and only here.
The script saves the values it deploys in $HOME/.apex-factory/<subscription-id>/datacenter.json.
Re-runs converge an existing datacenter to those values.

Azure Hybrid Benefit is on by default for vm-app01 (licenseType Windows_Server). It assumes you hold
eligible Windows Server licences with Software Assurance or subscriptions. Use -NoHybridBenefit to
deploy without it. vm-dev01 always uses Windows_Client (multitenant hosting rights), which Windows 11
on Azure needs. Quota is deliberately not checked.
.PARAMETER SubscriptionId
The member's workload subscription.
.PARAMETER MemberIndex
The member index n, 1-20. The datacenter uses 10.10.n.0/24.
.PARAMETER Location
The Azure region. Fallback: germanywestcentral.
.PARAMETER VmSize
The size of both VMs.
.PARAMETER DevImageSku
The Windows 11 Enterprise image SKU for vm-dev01.
.PARAMETER ScriptsRef
The git ref of this repo that the VMs download their configuration scripts from.
.PARAMETER NoHybridBenefit
Deploy vm-app01 without Azure Hybrid Benefit.
.PARAMETER AdminPassword
Overrides the lab password for labadmin on both VMs.
.PARAMETER SqlAppPassword
Overrides the lab password for the SQL login contosoapp.
.EXAMPLE
./scripts/Deploy-Datacenter.ps1 -SubscriptionId '<workload-subscription-id>' -MemberIndex 1
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Deploy-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SubscriptionId,
    [ValidateRange(1, 20)]
    [int] $MemberIndex = 1,
    [string] $Location = 'swedencentral',
    [string] $VmSize = 'Standard_D8as_v6',
    [string] $DevImageSku = 'win11-25h2-ent',
    [ValidatePattern('^[A-Za-z0-9._/-]+$')]
    [string] $ScriptsRef = 'main',
    [switch] $NoHybridBenefit,
    [securestring] $AdminPassword,
    [securestring] $SqlAppPassword
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$resourceGroup = 'rg-datacenter'
$repository = 'jonathan-vella/apex-factory-hackathon'
$template = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'infra', 'datacenter', 'main.bicep'
$secretsDir = Join-Path -Path $HOME -ChildPath '.apex-factory' -AdditionalChildPath $SubscriptionId
$secretsFile = Join-Path -Path $secretsDir -ChildPath 'datacenter.json'
$hybridBenefit = -not $NoHybridBenefit.IsPresent
# Fixed, documented lab password: see docs/backlog/README.md, Secrets.
$labPassword = 'FactoryLab-2026-Pw'
$adminPasswordOverride = $AdminPassword
$sqlAppPasswordOverride = $SqlAppPassword

function Invoke-AzureCli {
    param([string[]] $Arguments)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE)."
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

function ConvertTo-PlainText {
    param([securestring] $Value, [string] $Default)
    if (-not $Value) {
        return $Default
    }
    return [System.Net.NetworkCredential]::new('', $Value).Password
}

function Save-DatacenterSecret {
    New-Item -ItemType Directory -Force -Path $secretsDir | Out-Null
    $secrets = [ordered]@{
        adminUsername = 'labadmin'
        adminPassword = ConvertTo-PlainText -Value $adminPasswordOverride -Default $labPassword
        sqlAppLogin = 'contosoapp'
        sqlAppPassword = ConvertTo-PlainText -Value $sqlAppPasswordOverride -Default $labPassword
    }
    $secrets | ConvertTo-Json | Set-Content -Path $secretsFile -Encoding utf8NoBOM
    if (-not $IsWindows) {
        [System.IO.File]::SetUnixFileMode($secretsFile, [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite)
    }
    $source = if ($adminPasswordOverride -or $sqlAppPasswordOverride) { 'with your overrides' } else { 'the documented lab password' }
    Write-Information "Credentials ($source) saved in $secretsFile."
    return [pscustomobject] $secrets
}

$null = Invoke-AzureCli -Arguments @('account', 'show', '--subscription', $SubscriptionId)
$secrets = Save-DatacenterSecret

$ahbText = if ($hybridBenefit) {
    'ON for vm-app01 (Windows_Server). This assumes you hold eligible Windows Server licences with Software Assurance or subscriptions. Deploy with -NoHybridBenefit if you do not.'
}
else {
    'OFF for vm-app01 (-NoHybridBenefit). Windows Server is billed at the pay-as-you-go rate.'
}
$costText = if ($hybridBenefit) { 'about $1.25/hour while running' } else { 'about $2.00/hour while running' }

Write-Information @"

Deploying the datacenter for member $MemberIndex to ${Location}:
  Resource group   $resourceGroup
  Network          vnet-datacenter 10.10.$MemberIndex.0/24, snet-servers 10.10.$MemberIndex.0/25, nsg-servers,
                   nat-datacenter with pip-nat-datacenter, bas-datacenter (Bastion Developer, free)
  vm-app01         10.10.$MemberIndex.4, $VmSize, Windows Server 2022 + SQL Server 2022 Developer, IIS, MSMQ,
                   legacy Contoso University. P30 data disk for SQL Server
  vm-dev01         10.10.$MemberIndex.5, $VmSize, Windows 11 Enterprise ($DevImageSku), developer tools.
                   OS disk at performance tier P30
  Scripts          $repository at '$ScriptsRef'
Cost: $costText, about `$0.48/hour when both VMs are stopped (deallocated). There's no auto-shutdown.
Azure Hybrid Benefit: $ahbText
vm-dev01 always uses Windows_Client (multitenant hosting rights), which Windows 11 on Azure needs.
Quota is not checked. If the deployment fails on quota, request more or use another size or region.
This takes up to 60 minutes.

"@

$parametersFile = Join-Path ([System.IO.Path]::GetTempPath()) "datacenter-$([guid]::NewGuid()).parameters.json"
$parameters = [ordered]@{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = [ordered]@{
        location = @{ value = $Location }
        memberIndex = @{ value = $MemberIndex }
        vmSize = @{ value = $VmSize }
        devImageSku = @{ value = $DevImageSku }
        enableHybridBenefit = @{ value = $hybridBenefit }
        adminPassword = @{ value = $secrets.adminPassword }
        sqlAppPassword = @{ value = $secrets.sqlAppPassword }
        scriptsBaseUrl = @{ value = "https://raw.githubusercontent.com/$repository/$ScriptsRef/infra/datacenter/scripts" }
    }
}

$started = Get-Date
try {
    $parameters | ConvertTo-Json -Depth 5 | Set-Content -Path $parametersFile -Encoding utf8NoBOM
    if (-not $IsWindows) {
        [System.IO.File]::SetUnixFileMode($parametersFile, [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite)
    }
    Write-Information "Deployment started at $($started.ToString('HH:mm')). The VMs configure themselves through run commands."
    $deployment = Invoke-AzureCli -Arguments @(
        'deployment', 'sub', 'create',
        '--name', "datacenter-$MemberIndex",
        '--subscription', $SubscriptionId,
        '--location', $Location,
        '--template-file', $template,
        '--parameters', "@$parametersFile"
    )
}
finally {
    Remove-Item -Path $parametersFile -Force -ErrorAction SilentlyContinue
}

# The osDisk block has no performance tier, so vm-dev01's P30 tier is set on the disk. It changes without downtime.
$tier = (Invoke-AzureCli -Arguments @('disk', 'show', '--subscription', $SubscriptionId, '-g', $resourceGroup, '-n', 'osdisk-vm-dev01')).tier
if ($tier -ne 'P30') {
    Write-Information "Setting the vm-dev01 OS disk performance tier to P30 (was $tier)."
    $null = Invoke-AzureCli -Arguments @('disk', 'update', '--subscription', $SubscriptionId, '-g', $resourceGroup, '-n', 'osdisk-vm-dev01', '--set', 'tier=P30')
}

$elapsed = (Get-Date) - $started
$outputs = $deployment.properties.outputs
Write-Information @"

The datacenter is deployed ($([int] $elapsed.TotalMinutes) minutes).
  $($outputs.appVmName.value)  $($outputs.appVmPrivateIp.value)   http://$($outputs.appVmPrivateIp.value)/ from vm-dev01
  $($outputs.devVmName.value)  $($outputs.devVmPrivateIp.value)
  Bastion   $($outputs.bastionName.value)

Connect: in the Azure portal, open $resourceGroup > vm-dev01 > Connect > Bastion, and sign in as
  labadmin. Bastion Developer allows one session at a time. VS Code extensions install at first logon.
Credentials: labadmin and the SQL login contosoapp use the documented lab password unless you overrode it.
  They're saved in $secretsFile
Test:  ./scripts/Test-Datacenter.ps1 -SubscriptionId <subscription-id> -MemberIndex $MemberIndex
Stop when idle (you still pay for disks, about `$0.48/hour):
  az vm deallocate --subscription <subscription-id> -g $resourceGroup -n vm-app01 --no-wait
  az vm deallocate --subscription <subscription-id> -g $resourceGroup -n vm-dev01 --no-wait
Start again:
  az vm start --subscription <subscription-id> -g $resourceGroup -n vm-app01 --no-wait
  az vm start --subscription <subscription-id> -g $resourceGroup -n vm-dev01 --no-wait
Turn Azure Hybrid Benefit off after deployment:
  az vm update --subscription <subscription-id> -g $resourceGroup -n vm-app01 --license-type None
"@
