<#
.SYNOPSIS
Configures SQL Server 2022 on vm-app01 for the lab and for MI link.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM. Sets the default data, log and backup
folders on F:, mixed-mode authentication, TCP 1433, the Always On availability groups feature and the
startup trace flags -T1800 and -T9567, then restarts SQL Server if anything changed. Makes SYSTEM and the
local admin user sysadmins, so later run commands and the admin can manage the instance.
There's no SQL IaaS Agent extension: it conflicts with Arc onboarding.
.PARAMETER AdminUsername
The local admin user to make a sysadmin.
.EXAMPLE
.\Set-AppSqlServer.ps1 -AdminUsername labadmin
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $AdminUsername
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Set-AppSqlServer.log'
$serviceName = 'MSSQLSERVER'
$setupAppName = 'LabToolsSetup'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

function Invoke-Sql {
    param(
        [string] $Query,
        [string] $ApplicationName = 'LabTools'
    )
    $connectionString = "Server=localhost;Database=master;Integrated Security=SSPI;Application Name=$ApplicationName;Connect Timeout=15"
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        $command.CommandTimeout = 300
        $table = New-Object System.Data.DataTable
        $table.Load($command.ExecuteReader())
        Write-Output -InputObject $table -NoEnumerate
    }
    finally {
        $connection.Dispose()
    }
}

function Wait-Sql {
    param([string] $ApplicationName = 'LabTools')
    for ($i = 1; $i -le 40; $i++) {
        try {
            Invoke-Sql -Query 'SELECT 1' -ApplicationName $ApplicationName | Out-Null
            return
        }
        catch {
            Start-Sleep -Seconds 3
        }
    }
    throw 'SQL Server did not accept connections within 2 minutes.'
}

function Sync-RegistryValue {
    param(
        [string] $Path,
        [string] $Name,
        [object] $Value,
        [ValidateSet('String', 'DWord')]
        [string] $Type = 'String'
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    $current = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    if ($null -ne $current -and "$current" -eq "$Value") {
        return $false
    }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    $null = Write-LabLog "Set $Name = '$Value'."
    return $true
}

function Invoke-SqlRestart {
    param([string] $StartupOption = '')
    $agent = Get-Service -Name 'SQLSERVERAGENT' -ErrorAction SilentlyContinue
    $agentWasRunning = $agent -and $agent.Status -eq 'Running'
    Stop-Service -Name $serviceName -Force
    if ($StartupOption) {
        # net start passes the option to sqlservr, for example /mLabToolsSetup for single-user mode.
        & net.exe start $serviceName $StartupOption | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "net start $serviceName $StartupOption failed with exit code $LASTEXITCODE."
        }
    }
    else {
        Start-Service -Name $serviceName
        if ($agentWasRunning) {
            Start-Service -Name 'SQLSERVERAGENT'
        }
    }
}

try {
    for ($i = 1; -not (Get-Service -Name $serviceName -ErrorAction SilentlyContinue); $i++) {
        if ($i -gt 60) {
            throw "Service $serviceName not found after 10 minutes."
        }
        Start-Sleep -Seconds 10
    }
    if ((Get-Service -Name $serviceName).Status -ne 'Running') {
        Start-Service -Name $serviceName
    }

    $instanceId = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$serviceName
    $serverKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\MSSQLServer"
    Write-LabLog "Configuring instance $instanceId."

    $serviceAccount = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$serviceName'").StartName
    foreach ($folder in 'F:\SQLData', 'F:\SQLLog', 'F:\SQLBackup') {
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
        & icacls.exe $folder /grant "${serviceAccount}:(OI)(CI)F" /Q | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "icacls failed on $folder."
        }
    }

    $changed = $false
    $changed = (Sync-RegistryValue -Path $serverKey -Name 'DefaultData' -Value 'F:\SQLData') -or $changed
    $changed = (Sync-RegistryValue -Path $serverKey -Name 'DefaultLog' -Value 'F:\SQLLog') -or $changed
    $changed = (Sync-RegistryValue -Path $serverKey -Name 'BackupDirectory' -Value 'F:\SQLBackup') -or $changed
    $changed = (Sync-RegistryValue -Path $serverKey -Name 'LoginMode' -Value 2 -Type DWord) -or $changed
    $changed = (Sync-RegistryValue -Path "$serverKey\SuperSocketNetLib\Tcp" -Name 'Enabled' -Value 1 -Type DWord) -or $changed
    $changed = (Sync-RegistryValue -Path "$serverKey\SuperSocketNetLib\Tcp\IPAll" -Name 'TcpPort' -Value '1433') -or $changed
    $changed = (Sync-RegistryValue -Path "$serverKey\SuperSocketNetLib\Tcp\IPAll" -Name 'TcpDynamicPorts' -Value '') -or $changed
    $changed = (Sync-RegistryValue -Path "$serverKey\HADR" -Name 'HADR_Enabled' -Value 1 -Type DWord) -or $changed

    $parametersKey = "$serverKey\Parameters"
    $arguments = Get-ItemProperty -Path $parametersKey
    $argumentNames = @($arguments.PSObject.Properties.Name | Where-Object { $_ -match '^SQLArg\d+$' })
    $argumentValues = @($argumentNames | ForEach-Object { $arguments.$_ })
    $nextIndex = $argumentNames.Count
    foreach ($flag in '-T1800', '-T9567') {
        if ($argumentValues -notcontains $flag) {
            $changed = (Sync-RegistryValue -Path $parametersKey -Name "SQLArg$nextIndex" -Value $flag) -or $changed
            $nextIndex++
        }
    }

    Wait-Sql
    $isSysadmin = (Invoke-Sql -Query "SELECT IS_SRVROLEMEMBER('sysadmin')").Rows[0][0]
    if ($isSysadmin -ne 1) {
        Write-LabLog 'SYSTEM is not a sysadmin. Granting it in single-user mode.'
        Invoke-SqlRestart -StartupOption "/m$setupAppName"
        Wait-Sql -ApplicationName $setupAppName
        Invoke-Sql -ApplicationName $setupAppName -Query @"
IF SUSER_ID(N'NT AUTHORITY\SYSTEM') IS NULL CREATE LOGIN [NT AUTHORITY\SYSTEM] FROM WINDOWS;
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM];
"@ | Out-Null
        $changed = $true
    }

    if ($changed) {
        Write-LabLog 'Restarting SQL Server to apply the configuration.'
        Invoke-SqlRestart
        Wait-Sql
    }
    else {
        Write-LabLog 'SQL Server configuration already matches. No restart needed.'
    }

    $adminLogin = "$env:COMPUTERNAME\$AdminUsername"
    Invoke-Sql -Query @"
IF SUSER_ID(N'$adminLogin') IS NULL CREATE LOGIN [$adminLogin] FROM WINDOWS;
IF IS_SRVROLEMEMBER('sysadmin', N'$adminLogin') = 0 ALTER SERVER ROLE [sysadmin] ADD MEMBER [$adminLogin];
"@ | Out-Null

    $state = (Invoke-Sql -Query @"
SELECT CAST(SERVERPROPERTY('IsHadrEnabled') AS int) AS Hadr,
       CAST(SERVERPROPERTY('IsIntegratedSecurityOnly') AS int) AS WindowsOnly,
       CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS nvarchar(260)) AS DataPath,
       CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS nvarchar(260)) AS LogPath,
       CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(64)) AS Version
"@).Rows[0]
    $flags = @((Invoke-Sql -Query 'DBCC TRACESTATUS(-1) WITH NO_INFOMSGS').Rows | Where-Object { $_.Global -eq 1 } | ForEach-Object { [int] $_.TraceFlag })

    if ($state.Hadr -ne 1) { throw 'The availability groups feature is not enabled.' }
    if ($state.WindowsOnly -ne 0) { throw 'Mixed-mode authentication is not enabled.' }
    if ($state.DataPath -notlike 'F:\SQLData*' -or $state.LogPath -notlike 'F:\SQLLog*') { throw 'Default data or log folder is not on F:.' }
    foreach ($flag in 1800, 9567) {
        if ($flags -notcontains $flag) { throw "Trace flag $flag is not on." }
    }
    Write-LabLog "SQL Server $($state.Version) is configured: HADR on, mixed mode, TCP 1433, trace flags 1800 and 9567."
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
