#Requires -Version 7.4

<#
.SYNOPSIS
Bootstraps vm-dev01 in one command: installs missing tools (node 24 LTS, Python 3, azd), signs in to GitHub/Azure/azd, auto-detects member index and subscriptions, creates or clones the student's private repository on main, imports the kit, writes local settings, and opens VS Code.
.DESCRIPTION
Designed for students connecting to vm-dev01 through Azure Bastion (including on pre-existing vm-dev01 VMs deployed before
the single-clone update):
1. Installs Node.js 24 LTS, Python 3 and Azure Developer CLI (azd) machine-wide if they are missing on vm-dev01.
2. Signs in to GitHub CLI (with repo and workflow scopes), Azure CLI, and azd, configures git user.name and user.email,
   and sets AZURE_TOKEN_CREDENTIALS=AzureCliCredential.
3. Auto-detects MemberIndex from vm-dev01's private IPv4 address (10.10.<n>.5 or 10.<128..191>.<0..255>.5), verifies the
   matching workload subscription's vnet-datacenter address prefix, and resolves SharedSubscriptionId from the hub peering.
4. Creates the student's private GitHub repository (<GitHubOwner>/apex-factory-m<nn>) from jonathan-vella/apex-accelerator
   (or reuses an existing private repo), clones it to C:\src\<RepoName> on main, runs Import-Kit.ps1, and commits/pushes to main.
5. Writes factory/.local/settings.json and datacenter.json via Initialize-Settings.ps1 and opens VS Code.
Never prints tenant, subscription, or object GUIDs to the console.
.PARAMETER GitHubOwner
Optional GitHub organization or username where the student repository lives. Defaults to the signed-in gh username.
.PARAMETER RepoName
Optional repository name. Defaults to apex-factory-m<nn> (where <nn> is the zero-padded MemberIndex).
.PARAMETER TemplateRepository
GitHub template repository (owner/name) used when creating a new student repository. Defaults to jonathan-vella/apex-accelerator.
.PARAMETER KitRepository
GitHub repository (owner/name) passed to Import-Kit.ps1. Defaults to jonathan-vella/apex-factory-hackathon.
.PARAMETER Ref
Git ref (branch or commit) passed to Import-Kit.ps1. Defaults to main.
.PARAMETER TenantId
Optional Microsoft Entra tenant ID override. Auto-detected from the matched workload subscription when omitted.
.PARAMETER SubscriptionId
Optional workload subscription ID override. Auto-detected and verified against rg-datacenter/vnet-datacenter when omitted.
.PARAMETER SharedSubscriptionId
Optional shared services subscription ID override. Auto-detected from the hub VNet peering when omitted.
.PARAMETER MemberIndex
Optional member index n (1 or greater). Auto-detected from vm-dev01's private IPv4 address when omitted.
.PARAMETER Location
Optional Azure region override. Auto-detected from rg-datacenter when omitted.
.PARAMETER Suffix
Optional 6-character lowercase alphanumeric archetype suffix override.
.PARAMETER WorkspaceRoot
Parent directory where the student repository is cloned. Defaults to C:\src on Windows or ~/src on Linux/macOS.
.PARAMETER SkipToolInstall
Skip checking and installing Node.js 24 LTS, Python 3 and Azure Developer CLI (azd).
.PARAMETER SkipOpenCode
Skip launching VS Code at the end of setup.
.EXAMPLE
./scripts/Initialize-Workstation.ps1
.EXAMPLE
./scripts/Initialize-Workstation.ps1 -GitHubOwner 'contoso-org' -RepoName 'factory-student-03'
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidatePattern('^$|^[A-Za-z0-9._-]+$')]
    [string] $GitHubOwner = '',
    [ValidatePattern('^$|^[A-Za-z0-9._-]+$')]
    [string] $RepoName = '',
    [ValidatePattern('^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string] $TemplateRepository = 'jonathan-vella/apex-accelerator',
    [ValidatePattern('^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string] $KitRepository = 'jonathan-vella/apex-factory-hackathon',
    [ValidateNotNullOrEmpty()]
    [string] $Ref = 'main',
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $TenantId = '',
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $SubscriptionId = '',
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $SharedSubscriptionId = '',
    [ValidateRange(0, [int]::MaxValue)]
    [int] $MemberIndex = 0,
    [string] $Location = '',
    [ValidatePattern('^$|^[a-z0-9]{4,6}$')]
    [string] $Suffix = '',
    [string] $WorkspaceRoot = '',
    [switch] $SkipToolInstall,
    [switch] $SkipOpenCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false
$guidRegex = '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}'

if (-not $WorkspaceRoot) {
    $WorkspaceRoot = if ($IsWindows) { 'C:\src' } else { Join-Path $HOME 'src' }
}

function Protect-SensitiveText {
    param([string] $Text)
    if (-not $Text) { return '' }
    return ($Text -replace $guidRegex, '<id>')
}

function Sync-SessionPath {
    if ($IsWindows) {
        $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $combined = (@($machinePath, $userPath) | Where-Object { $_ }) -join ';'
        if ($combined) {
            $env:Path = $combined
        }
    }
}

function Test-UsablePython {
    param([string] $CommandPath = '')
    if (-not $CommandPath) {
        $cmd = Get-Command python -ErrorAction SilentlyContinue
        if (-not $cmd) { return $false }
        $CommandPath = $cmd.Source
    }
    if (-not $CommandPath) { return $false }
    # Windows 11 ships a Microsoft Store App Execution Alias at %LOCALAPPDATA%\Microsoft\WindowsApps\python.exe.
    if ($CommandPath -match '(?i)[\\/]Microsoft[\\/]WindowsApps[\\/]') { return $false }
    return $true
}

if (-not (Get-Command Install-MissingWorkstationTool -ErrorAction SilentlyContinue)) {
    function Install-MissingWorkstationTool {
    [CmdletBinding()]
    param(
        [bool] $NeedNode,
        [bool] $NeedAzd,
        [bool] $NeedPython = $false
    )
    if (-not $NeedNode -and -not $NeedAzd -and -not $NeedPython) { return }
    if (-not $IsWindows) {
        throw 'Automatic installation of node, Python and azd is supported on Windows (vm-dev01) only. Install node 24 LTS, Python 3 and azd manually on this OS.'
    }

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $installScript = {
        param([bool] $InstallNode, [bool] $InstallAzd, [bool] $InstallPython)
        $ErrorActionPreference = 'Stop'
        $ProgressPreference = 'SilentlyContinue'
        $downloadDir = 'C:\LabTools\downloads'
        $nodeDir = 'C:\Program Files\nodejs'
        $pythonDir = 'C:\Program Files\Python3'
        $azdDir = 'C:\Program Files\Azure Dev CLI'
        New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null

        function Add-MachinePathEntry {
            param([string] $Directory)
            $mp = [Environment]::GetEnvironmentVariable('Path', 'Machine')
            if (($mp -split ';') -notcontains $Directory) {
                [Environment]::SetEnvironmentVariable('Path', "$mp;$Directory", 'Machine')
            }
        }

        if ($InstallNode -and -not (Test-Path (Join-Path $nodeDir 'node.exe'))) {
            Write-Host 'Installing Node.js 24 LTS on vm-dev01...'
            $releases = Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' -UseBasicParsing
            $node24 = $releases | Where-Object { $_.version -match '^v24\.' -and $_.lts } | Select-Object -First 1
            if (-not $node24) {
                throw 'No Node.js 24 LTS release found in https://nodejs.org/dist/index.json.'
            }
            $msiPath = Join-Path $downloadDir "node-$($node24.version)-x64.msi"
            Invoke-WebRequest -Uri "https://nodejs.org/dist/$($node24.version)/node-$($node24.version)-x64.msi" -OutFile $msiPath -UseBasicParsing
            $proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/i', "`"$msiPath`"", '/qn', '/norestart') -PassThru -WindowStyle Hidden
            $null = $proc.Handle
            $proc.WaitForExit()
            if ($proc.ExitCode -notin 0, 3010) {
                throw "Node.js installer failed with exit code $($proc.ExitCode)."
            }
        }
        if ($InstallNode) { Add-MachinePathEntry -Directory $nodeDir }

        if ($InstallPython -and -not (Test-Path (Join-Path $pythonDir 'python.exe'))) {
            Write-Host 'Installing Python 3 on vm-dev01...'
            $pythonPage = (Invoke-WebRequest -Uri 'https://www.python.org/downloads/windows/' -UseBasicParsing).Content
            $pythonMatch = [regex]::Match($pythonPage, 'https://www\.python\.org/ftp/python/(3\.\d+\.\d+)/python-\1-amd64\.exe')
            if (-not $pythonMatch.Success) {
                throw 'No Python 3 Windows x64 installer found at https://www.python.org/downloads/windows/.'
            }
            $pythonVersion = $pythonMatch.Groups[1].Value
            $exePath = Join-Path $downloadDir "python-$pythonVersion-amd64.exe"
            Invoke-WebRequest -Uri $pythonMatch.Value -OutFile $exePath -UseBasicParsing
            $proc = Start-Process -FilePath $exePath -ArgumentList @('/quiet', 'InstallAllUsers=1', 'PrependPath=1', 'Include_test=0', "TargetDir=`"$pythonDir`"") -PassThru -WindowStyle Hidden
            $null = $proc.Handle
            $proc.WaitForExit()
            if ($proc.ExitCode -notin 0, 3010) {
                throw "Python installer failed with exit code $($proc.ExitCode)."
            }
        }
        if ($InstallPython) {
            if ((Test-Path (Join-Path $pythonDir 'python.exe')) -and -not (Test-Path (Join-Path $pythonDir 'python3.exe'))) {
                Copy-Item -Path (Join-Path $pythonDir 'python.exe') -Destination (Join-Path $pythonDir 'python3.exe') -Force
            }
            Add-MachinePathEntry -Directory $pythonDir
            Add-MachinePathEntry -Directory (Join-Path $pythonDir 'Scripts')
        }

        if ($InstallAzd -and -not (Test-Path (Join-Path $azdDir 'azd.exe'))) {
            Write-Host 'Installing Azure Developer CLI (azd) on vm-dev01...'
            $msiPath = Join-Path $downloadDir 'azd-windows-amd64.msi'
            Invoke-WebRequest -Uri 'https://azuresdkartifacts.z5.web.core.windows.net/azd/standalone/release/stable/azd-windows-amd64.msi' -OutFile $msiPath -UseBasicParsing
            $proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/i', "`"$msiPath`"", '/qn', '/norestart', 'ALLUSERS=1') -PassThru -WindowStyle Hidden
            $null = $proc.Handle
            $proc.WaitForExit()
            if ($proc.ExitCode -notin 0, 3010) {
                throw "Azure Developer CLI installer failed with exit code $($proc.ExitCode)."
            }
        }
        if ($InstallAzd) { Add-MachinePathEntry -Directory $azdDir }
    }

    if ($isAdmin) {
        & $installScript $NeedNode $NeedAzd $NeedPython
    }
    else {
        Write-Information 'Elevating to Administrator to install missing workstation tools (node 24 LTS / Python 3 / azd)...'
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("& { $($installScript.ToString()) } $([int]$NeedNode) $([int]$NeedAzd) $([int]$NeedPython)"))
        $pwshExe = Join-Path $PSHOME 'pwsh.exe'
        $elevated = Start-Process -FilePath $pwshExe -ArgumentList @('-NoProfile', '-EncodedCommand', $encoded) -Verb RunAs -PassThru -Wait
        if ($elevated.ExitCode -ne 0) {
            throw "Elevated tool installer failed with exit code $($elevated.ExitCode). Re-run Initialize-Workstation.ps1 in an Administrator PowerShell 7 session."
        }
    }
    Sync-SessionPath
    }
}

if (-not (Get-Command Get-LocalIPv4Address -ErrorAction SilentlyContinue)) {
    function Get-LocalIPv4Address {
        $netIpCmd = Get-Command Get-NetIPAddress -ErrorAction SilentlyContinue
        if ($netIpCmd) {
            return @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | ForEach-Object { "$($_.IPAddress)" } | Where-Object { $_ })
        }
        return @(
            [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
                ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
                Where-Object { $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
                ForEach-Object { $_.Address.ToString() }
        )
    }
}

function Resolve-MemberIndexFromIp {
    param([string[]] $IpAddresses)
    foreach ($ip in $IpAddresses) {
        if ($ip -match '^10\.10\.([1-9]\d*)\.5$') {
            return [int] $Matches[1]
        }
        if ($ip -match '^10\.(12[89]|1[3-8]\d|19[01])\.(\d+)\.5$') {
            $block = [int] $Matches[1] - 127
            $oct3 = [int] $Matches[2]
            $computed = ($block * 256) + $oct3
            if ($computed -ge 1) { return $computed }
        }
    }
    return 0
}

function Get-ExpectedDatacenterPrefix {
    param([int] $Index)
    $block = [int][Math]::Floor($Index / 256)
    $dcOct2 = if ($block -eq 0) { 10 } else { 127 + $block }
    $oct3 = $Index % 256
    return "10.$dcOct2.$oct3.0/24"
}

function Invoke-GitHubCli {
    param(
        [string[]] $Arguments,
        [switch] $AllowFailure,
        [switch] $AllowNotFound
    )
    $output = & gh @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($exitCode -ne 0) {
        if ($AllowFailure) { return $null }
        if ($AllowNotFound -and $text -match '(?i)\b404\b|Not Found') { return $null }
        $operation = Protect-SensitiveText -Text (($Arguments | Select-Object -First 3) -join ' ')
        $safeDetail = Protect-SensitiveText -Text (($output | ForEach-Object { $_.ToString() }) -join ' ')
        throw "GitHub CLI '$operation' failed (exit $exitCode): $safeDetail"
    }
    $trimmed = $text.Trim()
    if ($trimmed.StartsWith('{') -or $trimmed.StartsWith('[')) {
        return ($trimmed | ConvertFrom-Json)
    }
    return $text
}

function Invoke-AzureCli {
    param(
        [string[]] $Arguments,
        [switch] $AllowFailure
    )
    $output = & az @Arguments --only-show-errors 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }) -join "`n"
    if ($exitCode -ne 0) {
        if ($AllowFailure) { return $null }
        $operation = Protect-SensitiveText -Text (($Arguments | Select-Object -First 3) -join ' ')
        throw "Azure CLI '$operation' failed (exit $exitCode)."
    }
    $trimmed = $text.Trim()
    if ($trimmed.StartsWith('{') -or $trimmed.StartsWith('[')) {
        return ($trimmed | ConvertFrom-Json)
    }
    return $trimmed
}

function Invoke-Git {
    param(
        [string] $Path,
        [string[]] $Arguments,
        [switch] $AllowFailure
    )
    $output = & git -C $Path @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $safeText = Protect-SensitiveText -Text $text
        throw "git $($Arguments -join ' ') failed (exit $exitCode): $safeText"
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $text.Trim()
    }
}

# Step 1: Ensure node 24 LTS, Python 3 and azd are installed on pre-existing vm-dev01 VMs.
Sync-SessionPath
if (-not $SkipToolInstall) {
    $needNode = $null -eq (Get-Command node -ErrorAction SilentlyContinue)
    $needAzd = $null -eq (Get-Command azd -ErrorAction SilentlyContinue)
    $needPython = -not (Test-UsablePython)
    if ($needNode -or $needAzd -or $needPython) {
        if ($PSCmdlet.ShouldProcess('vm-dev01', 'Install missing Node.js 24 LTS, Python 3 and/or Azure Developer CLI (azd)')) {
            Install-MissingWorkstationTool -NeedNode $needNode -NeedAzd $needAzd -NeedPython $needPython
        }
    }
}

# Step 2: Sign in to GitHub, Azure CLI, and azd, and set AZURE_TOKEN_CREDENTIALS.
$ghStatusOut = & gh auth status 2>&1
$ghStatusExit = $LASTEXITCODE
$ghStatusText = ($ghStatusOut | ForEach-Object { $_.ToString() }) -join "`n"
if ($ghStatusExit -ne 0) {
    Write-Information 'Signing in to GitHub CLI (with repo and workflow scopes)...'
    & gh auth login --hostname github.com --git-protocol https --scopes repo,workflow --web
    if ($LASTEXITCODE -ne 0) {
        throw 'GitHub CLI sign-in failed.'
    }
}
elseif ($ghStatusText -match 'Token scopes:' -and $ghStatusText -notmatch '(?i)\bworkflow\b') {
    Write-Information 'Refreshing GitHub CLI token to add the workflow scope...'
    & gh auth refresh --hostname github.com --scopes repo,workflow
    if ($LASTEXITCODE -ne 0) {
        throw 'GitHub CLI token refresh for workflow scope failed.'
    }
}

$null = Invoke-GitHubCli -Arguments @('auth', 'setup-git')
$ghUser = Invoke-GitHubCli -Arguments @('api', 'user')
if ($null -eq $ghUser -or -not $ghUser.PSObject.Properties['login'] -or -not "$($ghUser.login)".Trim()) {
    throw 'Could not resolve the signed-in GitHub user from gh api user.'
}
$ghLogin = "$($ghUser.login)".Trim()
$gitAuthorName = if ($ghUser.PSObject.Properties['name'] -and "$($ghUser.name)".Trim()) { "$($ghUser.name)".Trim() } else { $ghLogin }
$gitAuthorEmail = "$($ghUser.id)+$ghLogin@users.noreply.github.com"
& git config --global user.name $gitAuthorName
& git config --global user.email $gitAuthorEmail
if (-not $GitHubOwner) {
    $GitHubOwner = $ghLogin
}

$azCurrent = Invoke-AzureCli -Arguments @('account', 'show', '-o', 'json') -AllowFailure
if ($null -eq $azCurrent) {
    Write-Information 'Signing in to Azure CLI...'
    $loginArgs = @('login', '--use-device-code')
    if ($TenantId) { $loginArgs += @('--tenant', $TenantId) }
    $null = Invoke-AzureCli -Arguments $loginArgs
}

if ($IsWindows) {
    [Environment]::SetEnvironmentVariable('AZURE_TOKEN_CREDENTIALS', 'AzureCliCredential', 'User')
}
$env:AZURE_TOKEN_CREDENTIALS = 'AzureCliCredential'

if (Get-Command azd -ErrorAction SilentlyContinue) {
    $null = & azd auth login --check-status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Information 'Signing in to Azure Developer CLI (azd)...'
        $azdArgs = @('auth', 'login', '--use-device-code')
        if ($TenantId) { $azdArgs += @('--tenant-id', $TenantId) }
        & azd @azdArgs
        if ($LASTEXITCODE -ne 0) {
            throw 'azd auth login failed.'
        }
    }
}

# Step 3: Auto-detect MemberIndex, SubscriptionId, TenantId, Location, and SharedSubscriptionId.
if ($MemberIndex -le 0) {
    $ips = @(Get-LocalIPv4Address)
    $MemberIndex = Resolve-MemberIndexFromIp -IpAddresses $ips
    if ($MemberIndex -le 0) {
        throw 'Could not auto-detect MemberIndex from local IPv4 addresses (expected 10.10.<n>.5 or 10.<128..191>.<0..255>.5). Re-run with -MemberIndex <n>.'
    }
}
$expectedDcPrefix = Get-ExpectedDatacenterPrefix -Index $MemberIndex

if (-not $SubscriptionId) {
    $accounts = @(Invoke-AzureCli -Arguments @('account', 'list', '--query', "[?state=='Enabled'].{id:id, tenantId:tenantId, name:name}", '-o', 'json'))
    if ($accounts.Count -eq 0) {
        throw 'No enabled Azure subscriptions found for the signed-in account.'
    }
    $matchedAccounts = [System.Collections.Generic.List[object]]::new()
    foreach ($acct in $accounts) {
        $prefixes = @(Invoke-AzureCli -Arguments @('network', 'vnet', 'show', '-g', 'rg-datacenter', '-n', 'vnet-datacenter', '--subscription', "$($acct.id)", '--query', 'addressSpace.addressPrefixes', '-o', 'json') -AllowFailure)
        if ($prefixes -contains $expectedDcPrefix) {
            $matchedAccounts.Add($acct)
        }
    }
    if ($matchedAccounts.Count -eq 0) {
        throw "No accessible subscription contains rg-datacenter/vnet-datacenter with address prefix '$expectedDcPrefix' for member index $MemberIndex. Pass -SubscriptionId explicitly."
    }
    if ($matchedAccounts.Count -gt 1) {
        throw "Multiple accessible subscriptions ($($matchedAccounts.Count)) contain vnet-datacenter with prefix '$expectedDcPrefix'. Pass -SubscriptionId explicitly."
    }
    $SubscriptionId = "$($matchedAccounts[0].id)".Trim()
    if (-not $TenantId -and $matchedAccounts[0].PSObject.Properties['tenantId']) {
        $TenantId = "$($matchedAccounts[0].tenantId)".Trim()
    }
}
else {
    $prefixes = @(Invoke-AzureCli -Arguments @('network', 'vnet', 'show', '-g', 'rg-datacenter', '-n', 'vnet-datacenter', '--subscription', $SubscriptionId, '--query', 'addressSpace.addressPrefixes', '-o', 'json') -AllowFailure)
    if ($prefixes -notcontains $expectedDcPrefix) {
        throw "The supplied workload subscription does not contain rg-datacenter/vnet-datacenter with prefix '$expectedDcPrefix' for member index $MemberIndex."
    }
}

$null = Invoke-AzureCli -Arguments @('account', 'set', '--subscription', $SubscriptionId)
if (-not $TenantId) {
    $subInfo = Invoke-AzureCli -Arguments @('account', 'show', '--subscription', $SubscriptionId, '-o', 'json')
    $TenantId = "$($subInfo.tenantId)".Trim()
}

if (-not $Location) {
    $detectedLoc = Invoke-AzureCli -Arguments @('group', 'show', '-n', 'rg-datacenter', '--subscription', $SubscriptionId, '--query', 'location', '-o', 'tsv') -AllowFailure
    $Location = if ("$detectedLoc".Trim()) { "$detectedLoc".Trim() } else { 'swedencentral' }
}

if (-not $SharedSubscriptionId) {
    foreach ($pair in @(@('rg-datacenter', 'vnet-datacenter'), @('rg-spoke', 'vnet-spoke'))) {
        $remoteIds = @(Invoke-AzureCli -Arguments @('network', 'vnet', 'peering', 'list', '-g', $pair[0], '--vnet-name', $pair[1], '--subscription', $SubscriptionId, '--query', '[].remoteVirtualNetwork.id', '-o', 'json') -AllowFailure)
        foreach ($remId in $remoteIds) {
            if ("$remId" -match '/subscriptions/([0-9a-fA-F-]{36})/resourceGroups/rg-hub/') {
                $SharedSubscriptionId = $Matches[1]
                break
            }
        }
        if ($SharedSubscriptionId) { break }
    }
}

if (-not $Suffix) {
    $existingUniRg = Invoke-AzureCli -Arguments @('group', 'list', '--subscription', $SubscriptionId, '--query', "[?starts_with(name,'rg-university-')].name | [0]", '-o', 'tsv') -AllowFailure
    if ("$existingUniRg" -match '^rg-university-([a-z0-9]{4,6})$') {
        $Suffix = $Matches[1]
    }
}

# Step 4: Create or clone the student's single private repository and run Import-Kit.ps1.
if (-not $RepoName) {
    $RepoName = "apex-factory-m$('{0:D2}' -f $MemberIndex)"
}
$fullRepo = "$GitHubOwner/$RepoName"
$repoUrl = "https://github.com/$fullRepo.git"
$repoPath = Join-Path $WorkspaceRoot $RepoName

New-Item -ItemType Directory -Force -Path $WorkspaceRoot | Out-Null

$existingRepo = Invoke-GitHubCli -Arguments @('api', "repos/$fullRepo") -AllowNotFound
if ($null -ne $existingRepo) {
    if ($existingRepo.private -ne $true) {
        throw "Existing repository '$fullRepo' is not private. Refusing to use a public repository."
    }
}
elseif ($PSCmdlet.ShouldProcess($fullRepo, "Create private repository from $TemplateRepository")) {
    Write-Information "Creating private repository '$fullRepo' from '$TemplateRepository'..."
    $null = Invoke-GitHubCli -Arguments @('repo', 'create', $fullRepo, '--private', '--template', $TemplateRepository)
    $populated = $false
    for ($attempt = 1; $attempt -le 12; $attempt++) {
        $commits = Invoke-GitHubCli -Arguments @('api', "repos/$fullRepo/commits?per_page=1") -AllowFailure
        $commitItems = @($commits | Where-Object { $null -ne $_ -and $_.PSObject.Properties['sha'] })
        if ($commitItems.Count -ge 1) {
            $populated = $true
            break
        }
        if ($attempt -lt 12) {
            Start-Sleep -Seconds 2
        }
    }
    if (-not $populated) {
        throw "Repository '$fullRepo' was created, but template commit population did not finish in time. Re-run Initialize-Workstation.ps1 to converge."
    }
}

if (-not (Test-Path (Join-Path $repoPath '.git'))) {
    if ($PSCmdlet.ShouldProcess($repoPath, "Clone $repoUrl")) {
        $cloneOut = & git clone $repoUrl $repoPath 2>&1
        if ($LASTEXITCODE -ne 0) {
            $safeCloneErr = Protect-SensitiveText -Text (($cloneOut | ForEach-Object { $_.ToString() }) -join ' ')
            throw "git clone failed for '$fullRepo': $safeCloneErr"
        }
    }
}
else {
    $originUrl = (Invoke-Git -Path $repoPath -Arguments @('remote', 'get-url', 'origin')).Output
    if ($originUrl -notmatch "(?i)$([regex]::Escape($fullRepo))(\.git)?/?$") {
        throw "Existing clone at '$repoPath' points to '$originUrl' instead of '$fullRepo'. Refusing to modify an unrelated clone."
    }
    $dirtyBefore = (Invoke-Git -Path $repoPath -Arguments @('status', '--porcelain')).Output
    if ($dirtyBefore) {
        throw "Existing clone at '$repoPath' has uncommitted changes. Commit or stash your changes before re-running Initialize-Workstation.ps1."
    }
    $null = Invoke-Git -Path $repoPath -Arguments @('switch', 'main')
    $null = Invoke-Git -Path $repoPath -Arguments @('pull', '--rebase', 'origin', 'main')
}

$importKitScript = Join-Path $PSScriptRoot 'Import-Kit.ps1'
$tempImportScript = ''
try {
    if (-not (Test-Path $importKitScript)) {
        $tempImportScript = Join-Path ([System.IO.Path]::GetTempPath()) "Import-Kit-$([guid]::NewGuid().ToString('N')).ps1"
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$KitRepository/$Ref/scripts/Import-Kit.ps1" -OutFile $tempImportScript -UseBasicParsing
        $importKitScript = $tempImportScript
    }

    if ($PSCmdlet.ShouldProcess($repoPath, "Run Import-Kit.ps1 ($KitRepository@$Ref)")) {
        $importOut = & $importKitScript -Destination $repoPath -KitRepository $KitRepository -Ref $Ref -Force *>&1
        foreach ($line in $importOut) {
            if ($null -ne $line) {
                Write-Information (Protect-SensitiveText -Text $line.ToString())
            }
        }
    }
}
finally {
    if ($tempImportScript -and (Test-Path $tempImportScript)) {
        Remove-Item -LiteralPath $tempImportScript -Force -ErrorAction SilentlyContinue
    }
}

$oldLefthook = $env:LEFTHOOK
$env:LEFTHOOK = '0'
try {
    $null = Invoke-Git -Path $repoPath -Arguments @('add', '-A')
    $dirtyAfter = (Invoke-Git -Path $repoPath -Arguments @('status', '--porcelain')).Output
    if ($dirtyAfter) {
        $null = Invoke-Git -Path $repoPath -Arguments @('commit', '-m', 'chore: import the factory kit')
    }
    $aheadRes = Invoke-Git -Path $repoPath -Arguments @('rev-list', '--count', 'origin/main..HEAD') -AllowFailure
    $aheadCount = 0
    if ($aheadRes.ExitCode -eq 0 -and [int]::TryParse($aheadRes.Output, [ref] $aheadCount) -and $aheadCount -gt 0) {
        $null = Invoke-Git -Path $repoPath -Arguments @('push', 'origin', 'main')
    }
}
finally {
    if ($null -eq $oldLefthook) {
        Remove-Item Env:LEFTHOOK -ErrorAction SilentlyContinue
    }
    else {
        $env:LEFTHOOK = $oldLefthook
    }
}

# Step 5: Write factory/.local/settings.json and datacenter.json, then open VS Code.
$settingsScript = Join-Path $repoPath 'factory/scripts/Initialize-Settings.ps1'
if (-not (Test-Path $settingsScript)) {
    throw "Expected '$settingsScript' was not found after Import-Kit.ps1."
}
$existingSettingsFile = Join-Path $repoPath 'factory/.local/settings.json'
if (-not $Suffix -and (Test-Path $existingSettingsFile)) {
    $savedSettings = Get-Content -Raw -Path $existingSettingsFile | ConvertFrom-Json
    if ($savedSettings.PSObject.Properties['suffix'] -and "$($savedSettings.suffix)".Trim()) {
        $Suffix = "$($savedSettings.suffix)".Trim()
    }
}

$settingsArgs = @{
    TenantId            = $TenantId
    SubscriptionId      = $SubscriptionId
    MemberIndex         = $MemberIndex
    Location            = $Location
    WriteLabCredentials = $true
}
if ($SharedSubscriptionId) {
    $settingsArgs['SharedSubscriptionId'] = $SharedSubscriptionId
}
if ($Suffix) {
    $settingsArgs['Suffix'] = $Suffix
}

$settingsOut = & $settingsScript @settingsArgs *>&1
foreach ($line in $settingsOut) {
    if ($null -ne $line) {
        Write-Information (Protect-SensitiveText -Text $line.ToString())
    }
}

Write-Information "Workstation ready at '$repoPath' on branch 'main' for member $MemberIndex."
if (-not $SkipOpenCode) {
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        & $codeCmd.Source $repoPath
    }
}
