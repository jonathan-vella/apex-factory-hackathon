<#
.SYNOPSIS
Writes the installed developer tool versions on vm-dev01 to C:\LabTools\versions.txt.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM, after the installs. Also prints the
versions, so they show in the run command output.
.EXAMPLE
.\Write-DevVersions.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Write-DevVersions.log'
$versionsFile = 'C:\LabTools\versions.txt'
$vswhere = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

function Get-NativeOutput {
    param([string] $FilePath, [string[]] $ArgumentList, [switch] $All)
    # Windows PowerShell 5.1 turns native stderr into terminating errors under 'Stop'.
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& $FilePath @ArgumentList 2>&1 | ForEach-Object { "$_" } | Where-Object { $_.Trim() })
        if ($All) {
            return ($output -join ', ')
        }
        return ($output | Select-Object -First 1)
    }
    catch {
        return 'not found'
    }
}

try {
    # The run command inherits the agent's PATH from boot, so read the current machine PATH.
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine')

    $versions = [ordered]@{
        'Visual Studio Code'                = (Get-Item 'C:\Program Files\Microsoft VS Code\Code.exe').VersionInfo.ProductVersion
        'Git'                               = Get-NativeOutput -FilePath 'git' -ArgumentList '--version'
        'GitHub CLI'                        = Get-NativeOutput -FilePath 'gh' -ArgumentList '--version'
        'PowerShell 7'                      = Get-NativeOutput -FilePath 'pwsh' -ArgumentList '-NoProfile', '-Command', '$PSVersionTable.PSVersion.ToString()'
        'Azure CLI'                         = Get-NativeOutput -FilePath 'az' -ArgumentList '--version'
        'Bicep'                             = Get-NativeOutput -FilePath 'bicep' -ArgumentList '--version'
        '.NET SDKs'                         = Get-NativeOutput -FilePath 'dotnet' -ArgumentList '--list-sdks' -All
        '.NET Framework 4.8 Developer Pack' = if (Test-Path 'C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8\mscorlib.dll') { 'installed' } else { 'not found' }
        'NuGet CLI'                         = (Get-Item 'C:\Program Files\NuGet\nuget.exe').VersionInfo.FileVersion
        'VS Build Tools'                    = Get-NativeOutput -FilePath $vswhere -ArgumentList '-products', 'Microsoft.VisualStudio.Product.BuildTools', '-property', 'catalog_productDisplayVersion'
        'SSMS'                              = Get-NativeOutput -FilePath $vswhere -ArgumentList '-products', 'Microsoft.VisualStudio.Product.SSMS', '-property', 'catalog_productDisplayVersion'
        'Windows'                           = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | ForEach-Object { "$($_.DisplayVersion) build $($_.CurrentBuild).$($_.UBR)" })
    }

    $lines = @("# vm-dev01 tool versions, $(Get-Date -Format 'yyyy-MM-dd')") + @($versions.GetEnumerator() | ForEach-Object { '{0}: {1}' -f $_.Key, $_.Value })
    Set-Content -Path $versionsFile -Value $lines
    Write-LabLog "Wrote $versionsFile."
    $lines | ForEach-Object { Write-Output $_ }
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
