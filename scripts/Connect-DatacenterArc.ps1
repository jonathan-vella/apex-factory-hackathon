#Requires -Version 7.4

<#
.SYNOPSIS
Onboards vm-app01 to Azure Arc unattended, with your own sign-in. Lab only.
.DESCRIPTION
The member's Arc onboarding (C0), the only onboarding path. Arc on an Azure VM is a lab-only pattern, never a customer
pattern. Run it from Azure Cloud Shell or your own computer, signed in with az login. It uses your
Azure Resource Manager access token, not a service principal, so your account needs Virtual Machine
Contributor on vm-app01 and Azure Connected Machine Resource Administrator (or Contributor) on
rg-datacenter. The member's Owner role on the workload subscription covers both.

The script:
1. Refuses to run if vm-app01 is already an Arc machine or its guest agent is already off.
2. Removes the VM extensions from vm-app01 (the Arc pattern for Azure VMs needs that).
3. Sends one run command that stages the work and returns: it passes your token as a protected
   parameter and registers a one-time task that starts a minute later. Turning off the guest agent
   ends any run command, so the task does the rest, logged to C:\LabTools\logs\Connect-AppArc.log:
   it runs C:\LabTools\arc\Prepare-ArcOnAzureVm.ps1, installs the Connected Machine agent and
   connects it to rg-datacenter.
4. Waits up to 20 minutes for the Arc machine to be Connected, then up to 20 minutes for the
   SQL Server extension to report the SQL Server instance, and prints the next steps.

After it, run commands and VM extensions don't work on vm-app01 any more. Run anything that needs
a run command, such as Test-Datacenter.ps1's in-VM checks, before this script.
.PARAMETER SubscriptionId
The member's workload subscription, which holds rg-datacenter.
.PARAMETER MemberIndex
The member index n, 1-20. vm-app01 is 10.10.n.4.
.PARAMETER Location
The region of the Arc machine resource. Use the datacenter's region.
.EXAMPLE
./scripts/Connect-DatacenterArc.ps1 -SubscriptionId '<workload-subscription-id>' -MemberIndex 1
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Connect-DatacenterArc.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SubscriptionId,
    [ValidateRange(1, 20)]
    [int] $MemberIndex = 1,
    [string] $Location = 'swedencentral'
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$resourceGroup = 'rg-datacenter'
$vmName = 'vm-app01'
$runCommandName = 'arc-onboard'
$apiVersion = '2025-11-01'
$stageScript = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'infra', 'datacenter', 'scripts', 'Connect-AppArc.ps1'
$timeout = [TimeSpan]::FromMinutes(20)
$logHelp = @"
Connect to vm-app01 through Bastion (./scripts/Connect-DatacenterVm.ps1 -SubscriptionId <subscription-id> -VmName vm-app01,
  or the portal: $resourceGroup > $vmName > Connect > Bastion) and read C:\LabTools\logs\Connect-AppArc.log.
  The agent's own logs are in C:\ProgramData\AzureConnectedMachineAgent\Log, and azcmagent show prints its status.
"@

function Invoke-AzureCli {
    param([string[]] $Arguments, [switch] $AllowFailure)
    # Capture native stderr rather than letting the CLI print subscription IDs.
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($AllowFailure) {
            return $null
        }
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE): $(($output | Select-Object -Last 1))"
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

function Get-ArcMachine {
    $id = "/subscriptions/$SubscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.HybridCompute/machines/$vmName"
    return Invoke-AzureCli -Arguments @('resource', 'show', '--ids', $id) -AllowFailure
}

if (-not (Test-Path $stageScript)) {
    throw "$stageScript is missing. Run this script from a clone of the kit repo."
}
$account = Invoke-AzureCli -Arguments @('account', 'show', '--subscription', $SubscriptionId)

$arc = Get-ArcMachine
if ($arc) {
    throw @"
$vmName is already an Arc machine in $resourceGroup (status: $($arc.properties.status)). Arc changes can't be undone reliably,
so this script doesn't onboard it again. Check it with:
  az resource show -g $resourceGroup -n $vmName --resource-type Microsoft.HybridCompute/machines --subscription <subscription-id> --query properties.status
  or in the portal: Azure Arc > Machines. On the VM: azcmagent show
"@
}

$vm = Invoke-AzureCli -Arguments @('vm', 'show', '--show-details', '--subscription', $SubscriptionId, '-g', $resourceGroup, '-n', $vmName)
if ($vm.powerState -ne 'VM running') {
    throw "$vmName is '$($vm.powerState)'. Start it with: az vm start --subscription <subscription-id> -g $resourceGroup -n $vmName"
}
$expectedIp = "10.10.$MemberIndex.4"
if ($vm.privateIps -ne $expectedIp) {
    throw "$vmName has IP $($vm.privateIps), not $expectedIp. Check -MemberIndex."
}
$agentStatus = (Invoke-AzureCli -Arguments @('vm', 'get-instance-view', '--subscription', $SubscriptionId, '-g', $resourceGroup, '-n', $vmName)).instanceView.vmAgent.statuses[0].displayStatus
if ($agentStatus -ne 'Ready') {
    throw @"
The guest agent on $vmName is '$agentStatus', so run commands don't work: an earlier run probably got as far as the prep script.
Read C:\LabTools\logs\Connect-AppArc.log on $vmName through Bastion. If the onboarding didn't finish, redeploy $vmName and run this script again.
"@
}

Write-Information @"

Onboarding $vmName ($expectedIp) to Azure Arc in $resourceGroup, $Location. Lab only: Arc on an Azure VM is
for evaluation, never a customer pattern. After this, run commands and VM extensions stop working on $vmName.
Arc-enabled SQL Server Developer is free. This takes about 10-20 minutes.

"@

$started = Get-Date
foreach ($extension in @(Invoke-AzureCli -Arguments @('vm', 'extension', 'list', '--subscription', $SubscriptionId, '-g', $resourceGroup, '--vm-name', $vmName))) {
    if ($extension) {
        Write-Information "Removing the VM extension $($extension.name)."
        $null = Invoke-AzureCli -Arguments @('vm', 'extension', 'delete', '--subscription', $SubscriptionId, '-g', $resourceGroup, '--vm-name', $vmName, '-n', $extension.name)
    }
}

$token = (Invoke-AzureCli -Arguments @('account', 'get-access-token', '--subscription', $SubscriptionId, '--resource-type', 'arm')).accessToken
$body = [ordered]@{
    location = $vm.location
    properties = [ordered]@{
        source = @{ script = Get-Content -Path $stageScript -Raw }
        parameters = @(
            @{ name = 'SubscriptionId'; value = $SubscriptionId }
            @{ name = 'TenantId'; value = $account.tenantId }
            @{ name = 'Location'; value = $Location }
            @{ name = 'ResourceGroup'; value = $resourceGroup }
        )
        protectedParameters = @(
            @{ name = 'AccessToken'; value = $token }
        )
        asyncExecution = $false
        timeoutInSeconds = 300
        treatFailureAsDeploymentFailure = $false
    }
}
# The token goes in a temporary body file, never on a command line, and the file is deleted at once.
$bodyFile = Join-Path ([System.IO.Path]::GetTempPath()) "arc-onboard-$([guid]::NewGuid()).json"
$url = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachines/$vmName/runCommands/${runCommandName}?api-version=$apiVersion"
try {
    $body | ConvertTo-Json -Depth 6 | Set-Content -Path $bodyFile -Encoding utf8NoBOM
    if (-not $IsWindows) {
        [System.IO.File]::SetUnixFileMode($bodyFile, [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite)
    }
    Write-Information 'Staging the onboarding task with one run command.'
    $null = Invoke-AzureCli -Arguments @('rest', '--method', 'put', '--url', $url, '--body', "@$bodyFile")
}
finally {
    Remove-Item -Path $bodyFile -Force -ErrorAction SilentlyContinue
    $token = $null
}

$deadline = (Get-Date).AddMinutes(10)
do {
    Start-Sleep -Seconds 15
    $view = (Invoke-AzureCli -Arguments @('vm', 'run-command', 'show', '--subscription', $SubscriptionId, '-g', $resourceGroup, '--vm-name', $vmName, '--name', $runCommandName, '--instance-view')).instanceView
} while ($view.executionState -notin 'Succeeded', 'Failed', 'TimedOut', 'Canceled' -and (Get-Date) -lt $deadline)
if ($view.executionState -ne 'Succeeded' -or $view.exitCode -ne 0) {
    throw "The staging run command ended '$($view.executionState)' (exit $($view.exitCode)): $($view.output) $($view.error)"
}
Write-Information ($view.output.Trim())

Write-Information 'Waiting for the Arc machine to be Connected (up to 20 minutes).'
$deadline = (Get-Date) + $timeout
do {
    Start-Sleep -Seconds 30
    $arc = Get-ArcMachine
} while ($arc.properties.status -ne 'Connected' -and (Get-Date) -lt $deadline)
if ($arc.properties.status -ne 'Connected') {
    throw "$vmName didn't connect to Azure Arc within 20 minutes (status: '$($arc.properties.status)').`n$logHelp"
}
$connected = Get-Date
Write-Information "$vmName is Connected after $([int] ($connected - $started).TotalMinutes) minutes (agent $($arc.properties.agentVersion))."

Write-Information 'Waiting for the SQL Server extension to report the instance (up to 20 minutes).'
$deadline = (Get-Date) + $timeout
do {
    Start-Sleep -Seconds 30
    $sql = @(Invoke-AzureCli -Arguments @('resource', 'list', '--subscription', $SubscriptionId, '-g', $resourceGroup, '--resource-type', 'Microsoft.AzureArcData/sqlServerInstances') -AllowFailure)
} while (-not $sql[0] -and (Get-Date) -lt $deadline)
if (-not $sql[0]) {
    throw @"
$vmName is Connected, but no SQL Server instance appeared within 20 minutes. Check the WindowsAgent.SqlServer
extension in the portal (Azure Arc > Machines > $vmName > Extensions); it installs automatically.
$logHelp
"@
}

Write-Information @"

Done in $([int] ((Get-Date) - $started).TotalMinutes) minutes. Arc-enabled SQL Server: $($sql.name -join ', ') in $resourceGroup.
Next steps:
  1. Check it in the portal: Azure Arc > SQL Server instances > $($sql[0].name). Edition Developer is free.
  2. Run the Arc SQL migration assessment: open the instance > Migration > Assessment, and review the
     result for ContosoUniversity. It can take a while to become available after onboarding.
Run commands and VM extensions don't work on $vmName any more. Use Bastion to reach it:
  ./scripts/Connect-DatacenterVm.ps1 -SubscriptionId <subscription-id> -VmName $vmName
"@
