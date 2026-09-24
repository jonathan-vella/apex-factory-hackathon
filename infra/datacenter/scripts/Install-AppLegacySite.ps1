<#
.SYNOPSIS
Deploys the legacy Contoso University package to IIS on vm-app01 and warms it up.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM, after IIS, MSMQ and the database exist.
Downloads ContosoUniversity-legacy.zip, extracts it to C:\inetpub\ContosoUniversity, replaces the
Default Web Site with the ContosoUniversity site and app pool, points DefaultConnection at SQL Server
by IP, creates the MSMQ queue, sets permissions and firewall rules, then requests http://localhost/
so EnsureCreated() builds and seeds the database.
Only DefaultConnection changes in Web.config: the plain-text password and debug="true" are
deliberate assessment findings.
.PARAMETER AppVmIp
Private IP of vm-app01, used in the connection string.
.PARAMETER PackageUrl
Download URL of ContosoUniversity-legacy.zip.
.PARAMETER SqlAppPassword
Password of the contosoapp login, passed as a protected run command parameter.
.PARAMETER RunId
The deployment's run ID. It changes on every deployment so Azure re-runs the run command. Only logged.
.EXAMPLE
.\Install-AppLegacySite.ps1 -AppVmIp 10.10.1.4 -PackageUrl 'https://github.com/jonathan-vella/apex-factory-hackathon/releases/download/legacy-v1/ContosoUniversity-legacy.zip' -SqlAppPassword '<generated-password>'
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'SqlAppPassword',
    Justification = 'Run commands pass protected parameters as plain strings.')]
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $AppVmIp,
    [Parameter(Mandatory)]
    [string] $PackageUrl,
    [Parameter(Mandatory)]
    [string] $SqlAppPassword,
    [string] $RunId = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Install-AppLegacySite.log'
$siteName = 'ContosoUniversity'
$sitePath = 'C:\inetpub\ContosoUniversity'
$appPoolIdentity = "IIS AppPool\$siteName"
$downloadDir = 'C:\LabTools\downloads'
$stateDir = 'C:\LabTools\state'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

try {
    Write-LabLog "Run ID: $RunId"
    New-Item -ItemType Directory -Force -Path $downloadDir, $stateDir | Out-Null

    # 1. Package: extract only when it's new or changed, so a re-run leaves the site alone.
    $zip = Join-Path $downloadDir 'ContosoUniversity-legacy.zip'
    Invoke-WebRequest -Uri $PackageUrl -OutFile $zip -UseBasicParsing
    $hash = (Get-FileHash -Path $zip -Algorithm SHA256).Hash
    $hashFile = Join-Path $stateDir 'ContosoUniversity-legacy.sha256'
    $deployedHash = if (Test-Path $hashFile) { (Get-Content $hashFile -Raw).Trim() } else { '' }
    if ($hash -ne $deployedHash -or -not (Test-Path (Join-Path $sitePath 'Web.config'))) {
        Write-LabLog "Extracting the package ($hash) to $sitePath."
        New-Item -ItemType Directory -Force -Path $sitePath | Out-Null
        Expand-Archive -Path $zip -DestinationPath $sitePath -Force
        Set-Content -Path $hashFile -Value $hash
    }
    else {
        Write-LabLog 'Package already deployed.'
    }

    # 2. IIS: the ContosoUniversity site replaces the Default Web Site.
    Import-Module WebAdministration
    if (Get-Website -Name 'Default Web Site') {
        Remove-Website -Name 'Default Web Site'
        Write-LabLog 'Removed the Default Web Site.'
    }
    $poolPath = "IIS:\AppPools\$siteName"
    if (-not (Test-Path $poolPath)) {
        New-WebAppPool -Name $siteName | Out-Null
        Write-LabLog "Created app pool $siteName."
    }
    $pool = Get-Item $poolPath
    if ($pool.managedRuntimeVersion -ne 'v4.0') { Set-ItemProperty $poolPath -Name managedRuntimeVersion -Value 'v4.0' }
    if ($pool.managedPipelineMode -ne 'Integrated') { Set-ItemProperty $poolPath -Name managedPipelineMode -Value 'Integrated' }
    if ($pool.processModel.identityType -ne 'ApplicationPoolIdentity') { Set-ItemProperty $poolPath -Name processModel.identityType -Value 'ApplicationPoolIdentity' }

    if (-not (Get-Website -Name $siteName)) {
        # An explicit ID avoids a WebAdministration bug when no other site exists.
        New-Website -Name $siteName -Id 1 -Port 80 -PhysicalPath $sitePath -ApplicationPool $siteName | Out-Null
        Write-LabLog "Created site $siteName on port 80."
    }

    # 3. Web.config: only DefaultConnection changes.
    $webConfigPath = Join-Path $sitePath 'Web.config'
    $webConfig = New-Object System.Xml.XmlDocument
    $webConfig.PreserveWhitespace = $true
    $webConfig.Load($webConfigPath)
    $connection = $webConfig.SelectSingleNode("/configuration/connectionStrings/add[@name='DefaultConnection']")
    if (-not $connection) {
        throw 'DefaultConnection not found in Web.config.'
    }
    $connectionString = "Server=$AppVmIp;Database=ContosoUniversity;User ID=contosoapp;Password=$SqlAppPassword;MultipleActiveResultSets=True;TrustServerCertificate=True"
    if ($connection.GetAttribute('connectionString') -ne $connectionString) {
        $connection.SetAttribute('connectionString', $connectionString)
        $webConfig.Save($webConfigPath)
        Write-LabLog "Set DefaultConnection to SQL Server at $AppVmIp."
    }

    # 4. MSMQ queue named by Web.config, and permissions for the app pool identity.
    $queueNode = $webConfig.SelectSingleNode("/configuration/appSettings/add[@key='NotificationQueuePath']")
    if (-not $queueNode) {
        throw 'NotificationQueuePath not found in Web.config.'
    }
    $queuePath = $queueNode.GetAttribute('value')
    Add-Type -AssemblyName System.Messaging
    if (-not [System.Messaging.MessageQueue]::Exists($queuePath)) {
        [System.Messaging.MessageQueue]::Create($queuePath) | Out-Null
        Write-LabLog "Created queue $queuePath."
    }
    $queue = New-Object System.Messaging.MessageQueue $queuePath
    $queue.SetPermissions($appPoolIdentity, [System.Messaging.MessageQueueAccessRights]::FullControl)
    $queue.Dispose()

    $uploads = Join-Path $sitePath 'Uploads\TeachingMaterials'
    New-Item -ItemType Directory -Force -Path $uploads | Out-Null
    & icacls.exe $uploads /grant "${appPoolIdentity}:(OI)(CI)M" /Q | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "icacls failed on $uploads."
    }
    Write-LabLog "Granted $appPoolIdentity full control on the queue and Modify on Uploads\TeachingMaterials."

    # 5. Windows Firewall: HTTP and SQL Server from the private address space only.
    $rules = @(
        @{ Name = 'LabTools-HTTP-In'; DisplayName = 'Contoso University HTTP (10.0.0.0/8)'; Port = 80 },
        @{ Name = 'LabTools-SQL-In'; DisplayName = 'SQL Server (10.0.0.0/8)'; Port = 1433 }
    )
    foreach ($rule in $rules) {
        if (-not (Get-NetFirewallRule -Name $rule.Name -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name $rule.Name -DisplayName $rule.DisplayName -Direction Inbound -Protocol TCP `
                -LocalPort $rule.Port -RemoteAddress '10.0.0.0/8' -Action Allow -Profile Any | Out-Null
            Write-LabLog "Created firewall rule $($rule.DisplayName)."
        }
    }

    # 6. Warm-up: the first request runs EnsureCreated() and seeds the data.
    if ((Get-Website -Name $siteName).State -ne 'Started') {
        Start-Website -Name $siteName
    }
    $lastError = ''
    for ($attempt = 1; $attempt -le 10; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri 'http://localhost/' -UseBasicParsing -TimeoutSec 300
            if ($response.StatusCode -eq 200 -and $response.Content -match 'Contoso University') {
                Write-LabLog "Warm-up returned HTTP 200 on attempt $attempt."
                exit 0
            }
            $lastError = "HTTP $($response.StatusCode) without 'Contoso University'"
        }
        catch {
            $lastError = $_.Exception.Message
        }
        Write-LabLog "Warm-up attempt $attempt failed: $lastError"
        Start-Sleep -Seconds 15
    }
    throw "The app didn't return HTTP 200 after warm-up. Last error: $lastError"
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
