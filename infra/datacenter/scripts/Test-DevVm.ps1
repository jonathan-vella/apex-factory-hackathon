<#
.SYNOPSIS
Checks vm-dev01 from the inside: reach to vm-app01, the developer tools and outbound HTTPS.
.DESCRIPTION
Sent by scripts/Test-Datacenter.ps1 through az vm run-command invoke (Windows PowerShell 5.1, as
SYSTEM). Prints one line per check: LABCHECK|PASS or FAIL|check|detail. Changes nothing.
.PARAMETER AppVmIp
Private IP of vm-app01.
.EXAMPLE
.\Test-DevVm.ps1 -AppVmIp 10.10.1.4
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $AppVmIp
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Test-DevVm.log'
$vswhere = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'

# The run command inherits the agent's PATH from boot, so read the current machine PATH.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine')

function Write-Check {
    param([string] $Check, [bool] $Pass, [string] $Detail)
    $status = if ($Pass) { 'PASS' } else { 'FAIL' }
    $line = "LABCHECK|$status|$Check|$Detail"
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

function Get-NativeOutput {
    param([string] $FilePath, [string[]] $ArgumentList)
    # Windows PowerShell 5.1 turns native stderr into terminating errors under 'Stop'.
    $ErrorActionPreference = 'Continue'
    & $FilePath @ArgumentList 2>&1 | ForEach-Object { "$_" } | Where-Object { $_.Trim() }
}

function Test-Tool {
    param([string] $Name)
    $check = "dev: $Name installed"
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) {
        Write-Check -Check $check -Pass $false -Detail 'not on PATH'
        return
    }
    try {
        $output = @(Get-NativeOutput -FilePath $command.Source -ArgumentList '--version')
        Write-Check -Check $check -Pass ($LASTEXITCODE -eq 0) -Detail $output[0]
    }
    catch {
        Write-Check -Check $check -Pass $false -Detail $_.Exception.Message
    }
}

Invoke-Check "dev: http://$AppVmIp/ returns 200" {
    $response = Invoke-WebRequest -Uri "http://$AppVmIp/" -UseBasicParsing -TimeoutSec 120
    @(($response.StatusCode -eq 200), "HTTP $($response.StatusCode)")
}

Invoke-Check "dev: TCP 1433 on $AppVmIp open" {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $connected = $client.ConnectAsync($AppVmIp, 1433).Wait(10000) -and $client.Connected
        @($connected, $(if ($connected) { 'connected' } else { 'no connection in 10 s' }))
    }
    finally {
        $client.Dispose()
    }
}

Test-Tool -Name 'git'
Test-Tool -Name 'gh'
Test-Tool -Name 'pwsh'
Test-Tool -Name 'az'
Test-Tool -Name 'bicep'
Test-Tool -Name 'code'

Invoke-Check 'dev: dotnet SDK 10 installed' {
    $sdks = @(Get-NativeOutput -FilePath 'dotnet' -ArgumentList '--list-sdks')
    $sdk10 = @($sdks | Where-Object { $_ -match '^10\.' })
    @(($sdk10.Count -gt 0), $(if ($sdk10.Count) { ($sdk10[0] -split ' ')[0] } else { "SDKs: $($sdks -join ', ')" }))
}

Invoke-Check 'dev: msbuild installed' {
    $msbuild = Get-NativeOutput -FilePath $vswhere -ArgumentList '-products', '*', '-requires', 'Microsoft.Component.MSBuild', '-find', 'MSBuild\**\Bin\MSBuild.exe' | Select-Object -First 1
    if (-not $msbuild) {
        return @($false, 'not found by vswhere')
    }
    $version = Get-NativeOutput -FilePath $msbuild -ArgumentList '-version', '-nologo' | Select-Object -Last 1
    @(($LASTEXITCODE -eq 0), "MSBuild $version")
}

Invoke-Check 'dev: SSMS installed' {
    $path = Get-NativeOutput -FilePath $vswhere -ArgumentList '-products', 'Microsoft.VisualStudio.Product.SSMS', '-property', 'installationPath' | Select-Object -First 1
    $exe = if ($path) { Join-Path $path 'Common7\IDE\Ssms.exe' } else { '' }
    $found = $exe -and (Test-Path $exe)
    @($found, $(if ($found) { "SSMS $((Get-Item $exe).VersionInfo.ProductVersion)" } else { 'not found' }))
}

Invoke-Check 'dev: outbound HTTPS to github.com' {
    $response = Invoke-WebRequest -Uri 'https://github.com' -UseBasicParsing -TimeoutSec 30
    @(($response.StatusCode -eq 200), "HTTP $($response.StatusCode)")
}
