<#
.SYNOPSIS
Onboards vm-app01 to Azure Arc unattended: stages a one-time task from a run command, then the task connects.
.DESCRIPTION
Windows PowerShell 5.1. scripts/Connect-DatacenterArc.ps1 sends this script as a run command, because
turning off the guest agent ends any run command. It runs in two modes:

- Stage (the run command, as SYSTEM): checks that C:\LabTools\arc\Prepare-ArcOnAzureVm.ps1 exists,
  copies itself to C:\LabTools\arc, saves the settings and the access token in
  C:\LabTools\arc\connect.json (readable only by SYSTEM and Administrators), registers the one-time
  scheduled task Connect-AppArc that starts a minute later, and returns.
- Scheduled (the task, as SYSTEM): reads and deletes connect.json, removes the task, runs the prep
  script, installs the Azure Connected Machine agent and connects it with the token.

Both modes log to C:\LabTools\logs\Connect-AppArc.log. The token is the signed-in user's Azure
Resource Manager token, valid for about an hour; no service principal is used.
.PARAMETER AccessToken
The user's Azure Resource Manager access token, passed as a protected run command parameter.
.PARAMETER SubscriptionId
The subscription of the Arc machine resource.
.PARAMETER TenantId
The tenant of the subscription.
.PARAMETER Location
The region of the Arc machine resource.
.PARAMETER ResourceGroup
The resource group of the Arc machine resource.
.PARAMETER Scheduled
Run as the scheduled task: connect the agent with the staged settings.
.EXAMPLE
.\Connect-AppArc.ps1 -AccessToken '<token>' -SubscriptionId '<subscription-id>' -TenantId '<tenant-id>' -Location swedencentral
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'AccessToken',
    Justification = 'Run commands pass protected parameters as plain strings.')]
[CmdletBinding()]
param(
    [string] $AccessToken,
    [string] $SubscriptionId,
    [string] $TenantId,
    [string] $Location,
    [string] $ResourceGroup = 'rg-datacenter',
    [switch] $Scheduled
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Connect-AppArc.log'
$arcDir = 'C:\LabTools\arc'
$prepScript = Join-Path $arcDir 'Prepare-ArcOnAzureVm.ps1'
$taskScript = Join-Path $arcDir 'Connect-AppArc.ps1'
$settingsFile = Join-Path $arcDir 'connect.json'
$taskName = 'Connect-AppArc'
$agentExe = Join-Path $env:ProgramW6432 'AzureConnectedMachineAgent\azcmagent.exe'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

function Save-ProtectedSetting {
    param([Collections.IDictionary] $Settings)
    # The file gets its restricted ACL before it holds the token.
    New-Item -ItemType File -Force -Path $settingsFile | Out-Null
    $acl = New-Object Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($sid in 'S-1-5-18', 'S-1-5-32-544') {
        $identity = New-Object Security.Principal.SecurityIdentifier($sid)
        $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($identity, 'FullControl', 'Allow')))
    }
    Set-Acl -Path $settingsFile -AclObject $acl
    $Settings | ConvertTo-Json | Set-Content -Path $settingsFile -Encoding UTF8
}

function Invoke-Stage {
    param([Collections.IDictionary] $Settings)
    foreach ($value in $Settings.Values) {
        if (-not $value) {
            throw 'Stage mode needs -AccessToken, -SubscriptionId, -TenantId and -Location.'
        }
    }
    if (-not (Test-Path $prepScript)) {
        throw "$prepScript is missing. Re-run scripts/Deploy-Datacenter.ps1 so the datacenter places it."
    }
    if ((Test-Path $agentExe) -and ((& $agentExe show 2>&1 | Out-String) -match 'Agent Status\s*:\s*Connected')) {
        throw 'The Connected Machine agent is already connected. Check with: azcmagent show'
    }
    New-Item -ItemType Directory -Force -Path $arcDir | Out-Null
    if ($PSCommandPath -ne $taskScript) {
        Copy-Item -Path $PSCommandPath -Destination $taskScript -Force
    }
    Save-ProtectedSetting -Settings $Settings
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$taskScript`" -Scheduled"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
    Write-LabLog "Staged: the task $taskName starts at $($trigger.StartBoundary). It turns off the guest agent, so run commands end here."
}

function Invoke-Connect {
    if (-not (Test-Path $settingsFile)) {
        throw "$settingsFile is missing. Run scripts/Connect-DatacenterArc.ps1 again."
    }
    $settings = Get-Content -Path $settingsFile -Raw | ConvertFrom-Json
    Remove-Item -Path $settingsFile -Force
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-LabLog 'Read and deleted the staged settings, and removed the task.'

    & $prepScript | ForEach-Object { Write-LabLog "  prep: $_" }
    if ($LASTEXITCODE -ne 0) {
        throw "The prep script failed (exit $LASTEXITCODE). See C:\LabTools\logs\Prepare-ArcOnAzureVm.log."
    }

    if (-not (Test-Path $agentExe)) {
        $msi = Join-Path $arcDir 'AzureConnectedMachineAgent.msi'
        Write-LabLog 'Downloading the Azure Connected Machine agent.'
        Invoke-WebRequest -Uri 'https://aka.ms/AzureConnectedMachineAgent' -OutFile $msi -UseBasicParsing
        $installLog = Join-Path $logDir 'AzureConnectedMachineAgent-install.log'
        $install = Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i', "`"$msi`"", '/qn', '/l*v', "`"$installLog`"" -Wait -PassThru
        if ($install.ExitCode -notin 0, 3010) {
            throw "The agent install failed (exit $($install.ExitCode)). See $installLog."
        }
        Write-LabLog "Installed the agent (exit $($install.ExitCode))."
    }
    else {
        Write-LabLog 'The agent is already installed.'
    }

    Write-LabLog "Connecting to Azure Arc in $($settings.resourceGroup), $($settings.location)."
    $output = & $agentExe connect --resource-group $settings.resourceGroup --tenant-id $settings.tenantId --location $settings.location --subscription-id $settings.subscriptionId --cloud 'AzureCloud' --access-token $settings.accessToken 2>&1
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { Write-LabLog "  azcmagent: $_" }
    if ($exitCode -ne 0) {
        throw "azcmagent connect failed (exit $exitCode)."
    }
    Write-LabLog 'Connected to Azure Arc.'
}

try {
    if ($Scheduled) {
        Invoke-Connect
    }
    else {
        Invoke-Stage -Settings ([ordered]@{
                accessToken = $AccessToken
                subscriptionId = $SubscriptionId
                tenantId = $TenantId
                location = $Location
                resourceGroup = $ResourceGroup
            })
    }
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
