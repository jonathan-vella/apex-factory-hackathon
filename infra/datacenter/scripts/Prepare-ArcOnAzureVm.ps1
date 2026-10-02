<#
.SYNOPSIS
Prepares vm-app01 for Azure Arc: makes the Azure VM look like an on-premises server. Lab only.
.DESCRIPTION
Applies the pattern for evaluating Arc-enabled servers on an Azure VM
(https://learn.microsoft.com/azure/azure-arc/servers/plan-evaluate-on-azure-virtual-machine), in order:
1. Sets the machine environment variable MSFT_ARC_TEST to true, so the Connected Machine agent
   installs on an Azure VM.
2. Checks for VM extension handlers. VM extensions are Azure resources, so remove them from outside
   the VM first (portal: the VM > Extensions + applications > Uninstall, or az vm extension delete).
   Run command handlers are expected and ignored.
3. Turns off the Azure guest agent (WindowsAzureGuestAgent): disabled and stopped.
4. Blocks outbound traffic to both Azure IMDS addresses, 169.254.169.254 and 169.254.169.253, with
   Windows Firewall rules.

After it runs, run commands and VM extensions stop working on this VM, for good. Run anything that
needs a run command (for example Test-Datacenter.ps1's in-VM checks) before this script.

The datacenter deployment places this script in C:\LabTools\arc but doesn't run it. Run it as an
administrator (Windows PowerShell 5.1). It's idempotent and logs to
C:\LabTools\logs\Prepare-ArcOnAzureVm.log. This is a lab-only pattern, never a customer pattern.
.EXAMPLE
powershell -ExecutionPolicy Bypass -File C:\LabTools\arc\Prepare-ArcOnAzureVm.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Prepare-ArcOnAzureVm.log'
$imdsAddresses = [ordered]@{
    BlockAzureIMDS = '169.254.169.254'
    BlockAzureIMDS253 = '169.254.169.253'
}

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

try {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this script as an administrator.'
    }
    Write-LabLog 'WARNING: after this script, run commands and VM extensions stop working on this VM, for good.'

    if ([Environment]::GetEnvironmentVariable('MSFT_ARC_TEST', 'Machine') -ne 'true') {
        [Environment]::SetEnvironmentVariable('MSFT_ARC_TEST', 'true', 'Machine')
        Write-LabLog 'Set the machine environment variable MSFT_ARC_TEST=true.'
    }
    else {
        Write-LabLog 'MSFT_ARC_TEST is already true.'
    }
    $env:MSFT_ARC_TEST = 'true'

    $pluginsDir = 'C:\Packages\Plugins'
    if (Test-Path $pluginsDir) {
        $handlers = Get-ChildItem -Path $pluginsDir -Directory |
            Where-Object { $_.Name -notlike 'Microsoft.CPlat.Core.RunCommand*' } |
            Select-Object -ExpandProperty Name
        if ($handlers) {
            Write-LabLog "WARNING: VM extension handlers found: $($handlers -join ', '). Remove the extensions from outside the VM (portal: the VM > Extensions + applications > Uninstall)."
        }
        else {
            Write-LabLog 'No VM extension handlers other than run commands.'
        }
    }

    $agent = Get-Service -Name WindowsAzureGuestAgent -ErrorAction SilentlyContinue
    if ($agent) {
        if ($agent.StartType -ne 'Disabled') {
            Set-Service -Name WindowsAzureGuestAgent -StartupType Disabled
            Write-LabLog 'Disabled the Azure guest agent.'
        }
        if ($agent.Status -ne 'Stopped') {
            Stop-Service -Name WindowsAzureGuestAgent -Force
            Write-LabLog 'Stopped the Azure guest agent.'
        }
        Write-LabLog 'The Azure guest agent is disabled and stopped.'
    }
    else {
        Write-LabLog 'The Azure guest agent service is not installed.'
    }

    foreach ($rule in $imdsAddresses.GetEnumerator()) {
        if (-not (Get-NetFirewallRule -Name $rule.Key -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name $rule.Key -DisplayName "Block access to Azure IMDS ($($rule.Value))" -Enabled True -Profile Any -Direction Outbound -Action Block -RemoteAddress $rule.Value | Out-Null
            Write-LabLog "Blocked outbound traffic to $($rule.Value)."
        }
        else {
            Write-LabLog "Outbound traffic to $($rule.Value) is already blocked."
        }
    }

    Write-LabLog 'vm-app01 is ready for the Connected Machine agent. Open a new PowerShell window as an administrator before you run the onboarding script, so it sees MSFT_ARC_TEST.'
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
