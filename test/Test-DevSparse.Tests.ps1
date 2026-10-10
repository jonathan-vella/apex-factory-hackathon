#Requires -Version 7.4

<#
.SYNOPSIS
Tests the sparse checkout of the kit clone on vm-dev01 with local fixture repositories, never against Azure or GitHub.
.DESCRIPTION
Checks that the patterns in Install-DevTools.ps1 and in infra/datacenter/README.md match, then runs the same git
commands on a fresh clone and on an existing clone with a student's work branch: the left-out folders are absent,
the others are present, and commits, pushes, pulls, new branches and lifeline branches keep working.
.EXAMPLE
./test/Test-DevSparse.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$work = Join-Path $PSScriptRoot ".work-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $work | Out-Null
$passed = 0

$env:GIT_AUTHOR_NAME = $env:GIT_COMMITTER_NAME = 'Test'
$env:GIT_AUTHOR_EMAIL = $env:GIT_COMMITTER_EMAIL = 'test@example.com'
$env:GIT_CONFIG_GLOBAL = Join-Path $work 'gitconfig'
Set-Content -LiteralPath $env:GIT_CONFIG_GLOBAL -Value "[core]`n`tautocrlf = false`n[advice]`n`tdetachedHead = false"
$env:GIT_CONFIG_NOSYSTEM = '1'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
    $script:passed++
}

function Invoke-Git {
    # Runs git in a folder and returns the output; throws on a non-zero exit code unless -AllowFailure.
    param([string] $Path, [string[]] $Arguments, [switch] $AllowFailure)
    $output = (& git -C $Path @Arguments 2>&1 | ForEach-Object { "$_" }) -join "`n"
    if ($LASTEXITCODE -ne 0 -and -not $AllowFailure) { throw "git $($Arguments -join ' ') failed ($LASTEXITCODE) in ${Path}: $output" }
    return $output
}

function Add-Line {
    param([string] $Path, [string] $Text)
    Add-Content -LiteralPath $Path -Value $Text
}

try {
    # The pattern lists in the install script and in the README must be the same.
    $tokens = $null; $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'infra/datacenter/scripts/Install-DevTools.ps1'), [ref] $tokens, [ref] $parseErrors)
    Assert-True ($parseErrors.Count -eq 0) 'Install-DevTools.ps1 has parse errors.'
    $assignment = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$kitSparsePatterns' }, $true)
    Assert-True ($null -ne $assignment) 'Install-DevTools.ps1 has no $kitSparsePatterns.'
    $patterns = @($assignment.Right.FindAll({ param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true) | ForEach-Object { $_.Value })

    $readme = Get-Content -Raw (Join-Path $repoRoot 'infra/datacenter/README.md')
    $command = [regex]::Match($readme, '(?m)^git sparse-checkout set --no-cone (.+)$')
    Assert-True $command.Success 'The datacenter README has no sparse-checkout command.'
    $readmePatterns = @([regex]::Matches($command.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
    Assert-True (($patterns -join '|') -eq ($readmePatterns -join '|')) "The patterns differ.`nScript: $($patterns -join ' ')`nREADME: $($readmePatterns -join ' ')"

    $left = @('coach', 'facilitator', 'docs', 'site', 'test', '.vale')
    $kept = @('app', 'db', 'scripts', 'infra', 'archetype', 'templates', '.github')
    $leftFiles = @('.vale.ini', '.markdownlint-cli2.mjs', '.prettierignore', 'prettier.config.mjs', 'lefthook.yml', 'package.json', 'package-lock.json', '.node-version', '.nvmrc')
    $keptFiles = @('README.md', 'LICENSE', 'NOTICE', '.gitignore', '.gitattributes')

    # Fixture: a public kit with main and a lifeline branch that still carries the left-out folders.
    $origin = Join-Path $work 'origin.git'
    $member = Join-Path $work 'member.git'
    $seed = Join-Path $work 'seed'
    foreach ($bare in $origin, $member) { Invoke-Git $work @('init', '--quiet', '--bare', '--initial-branch=main', $bare) | Out-Null }
    Invoke-Git $work @('init', '--quiet', '--initial-branch=main', $seed) | Out-Null
    foreach ($dir in $left + $kept) {
        $folder = Join-Path $seed "$dir/inner"
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $folder 'file.txt') -Value "$dir v1"
    }
    foreach ($file in $leftFiles + $keptFiles) { Set-Content -LiteralPath (Join-Path $seed $file) -Value "$file v1" }
    Invoke-Git $seed @('add', '-A') | Out-Null
    Invoke-Git $seed @('commit', '--quiet', '-m', 'kit') | Out-Null
    Invoke-Git $seed @('remote', 'add', 'origin', $origin) | Out-Null
    Invoke-Git $seed @('push', '--quiet', 'origin', 'main') | Out-Null
    Invoke-Git $seed @('switch', '--quiet', '-c', 'lifeline/L3-servicebus') | Out-Null
    Add-Line (Join-Path $seed 'app/inner/file.txt') 'lifeline'
    Add-Line (Join-Path $seed 'coach/inner/file.txt') 'lifeline'
    Add-Line (Join-Path $seed 'docs/inner/file.txt') 'lifeline'
    Invoke-Git $seed @('commit', '--quiet', '-am', 'lifeline') | Out-Null
    Invoke-Git $seed @('push', '--quiet', 'origin', 'lifeline/L3-servicebus') | Out-Null
    Invoke-Git $seed @('switch', '--quiet', 'main') | Out-Null

    function Assert-Slim {
        param([string] $Clone, [string] $Label)
        foreach ($name in $left + $leftFiles) { Assert-True (-not (Test-Path (Join-Path $Clone $name))) "${Label}: $name should be absent." }
        foreach ($name in $kept + $keptFiles) { Assert-True (Test-Path (Join-Path $Clone $name)) "${Label}: $name should be present." }
        Assert-True ((Invoke-Git $Clone @('config', '--get', 'core.sparseCheckout')) -eq 'true') "${Label}: sparse checkout should be on."
    }

    # New deployment: the commands of Install-DevTools.ps1.
    $fresh = Join-Path $work 'fresh'
    Invoke-Git $work @('clone', '--quiet', '--no-checkout', $origin, $fresh) | Out-Null
    Invoke-Git $fresh (@('sparse-checkout', 'set', '--no-cone') + $patterns) | Out-Null
    Invoke-Git $fresh @('checkout', '--quiet') | Out-Null
    Assert-Slim $fresh 'fresh clone'
    Assert-True ((Invoke-Git $fresh @('status', '--short')) -eq '') 'A fresh sparse clone should have a clean status.'
    Assert-True ((Invoke-Git $fresh @('rev-parse', '--abbrev-ref', 'HEAD')) -eq 'main') 'A fresh clone should be on main.'

    # Existing deployment: a full clone with a student's committed, uncommitted and untracked work.
    $clone = Join-Path $work 'existing'
    Invoke-Git $work @('clone', '--quiet', $origin, $clone) | Out-Null
    Invoke-Git $clone @('remote', 'add', 'member', $member) | Out-Null
    Invoke-Git $clone @('switch', '--quiet', '-c', 'vm-dev01-work') | Out-Null
    Add-Line (Join-Path $clone 'app/inner/file.txt') 'task 1'
    Invoke-Git $clone @('commit', '--quiet', '-am', 'task 1') | Out-Null
    Invoke-Git $clone @('push', '--quiet', '-u', 'member', 'vm-dev01-work') | Out-Null
    Add-Line (Join-Path $clone 'app/inner/file.txt') 'uncommitted'
    Add-Line (Join-Path $clone 'README.md') 'uncommitted'
    Set-Content -LiteralPath (Join-Path $clone 'app/inner/untracked.txt') -Value 'untracked'
    $dirtyApp = Get-Content -Raw (Join-Path $clone 'app/inner/file.txt')
    $headBefore = Invoke-Git $clone @('rev-parse', 'HEAD')

    Invoke-Git $clone (@('sparse-checkout', 'set', '--no-cone') + $patterns) | Out-Null
    Assert-Slim $clone 'existing clone'
    Assert-True ((Invoke-Git $clone @('rev-parse', '--abbrev-ref', 'HEAD')) -eq 'vm-dev01-work') 'The work branch should stay checked out.'
    Assert-True ((Invoke-Git $clone @('rev-parse', 'HEAD')) -eq $headBefore) 'The commit should not change.'
    Assert-True ((Get-Content -Raw (Join-Path $clone 'app/inner/file.txt')) -eq $dirtyApp) 'Uncommitted changes must stay.'
    Assert-True ((Get-Content -Raw (Join-Path $clone 'app/inner/untracked.txt')).Trim() -eq 'untracked') 'Untracked files must stay.'

    # Running it again changes nothing.
    Invoke-Git $clone (@('sparse-checkout', 'set', '--no-cone') + $patterns) | Out-Null
    Assert-Slim $clone 'existing clone, second run'
    Assert-True ((Get-Content -Raw (Join-Path $clone 'app/inner/file.txt')) -eq $dirtyApp) 'A second run must keep uncommitted changes.'

    # Commit and push: the left-out files aren't recorded as deleted.
    Invoke-Git $clone @('add', '-A') | Out-Null
    Invoke-Git $clone @('commit', '--quiet', '-m', 'task 2') | Out-Null
    Assert-True ((Invoke-Git $clone @('diff', '--name-status', "$headBefore..HEAD")) -notmatch '(?m)^D\s') 'The commit must not delete files.'
    Invoke-Git $clone @('push', '--quiet') | Out-Null
    Assert-True ((Invoke-Git $clone @('rev-parse', 'HEAD')) -eq (Invoke-Git $clone @('rev-parse', 'member/vm-dev01-work'))) 'The push should reach the member remote.'
    $pushed = (& git "--git-dir=$member" ls-tree -r --name-only vm-dev01-work -- coach) -join "`n"
    Assert-True ($pushed -match 'coach/inner/file.txt') 'The pushed branch should still contain coach/.'

    # A new branch and a pull of main with upstream changes in left-out and kept folders.
    Invoke-Git $clone @('switch', '--quiet', '-c', 'scratch') | Out-Null
    Invoke-Git $clone @('switch', '--quiet', 'vm-dev01-work') | Out-Null
    Invoke-Git $clone @('branch', '--quiet', '-D', 'scratch') | Out-Null
    Add-Line (Join-Path $seed 'coach/inner/file.txt') 'upstream'
    Add-Line (Join-Path $seed 'app/inner/file.txt') 'upstream'
    Set-Content -LiteralPath (Join-Path $seed 'facilitator/new.md') -Value 'new'
    Invoke-Git $seed @('add', '-A') | Out-Null
    Invoke-Git $seed @('commit', '--quiet', '-m', 'upstream') | Out-Null
    Invoke-Git $seed @('push', '--quiet', 'origin', 'main') | Out-Null
    Invoke-Git $clone @('switch', '--quiet', 'main') | Out-Null
    Invoke-Git $clone @('pull', '--quiet') | Out-Null
    Assert-Slim $clone 'after pull'
    Assert-True ((Get-Content -Raw (Join-Path $clone 'app/inner/file.txt')) -match 'upstream') 'The pull should update kept folders.'
    Invoke-Git $clone @('switch', '--quiet', 'vm-dev01-work') | Out-Null

    # A lifeline branch holds the left-out folders; it must check out without them and push to the member remote.
    Invoke-Git $clone @('fetch', '--quiet', 'origin', 'lifeline/L3-servicebus:lifeline/L3-servicebus') | Out-Null
    Invoke-Git $clone @('switch', '--quiet', 'lifeline/L3-servicebus') | Out-Null
    Assert-Slim $clone 'lifeline branch'
    Assert-True ((Get-Content -Raw (Join-Path $clone 'app/inner/file.txt')) -match 'lifeline') 'The lifeline branch should bring its app changes.'
    Invoke-Git $clone @('push', '--quiet', '-u', 'member', 'lifeline/L3-servicebus') | Out-Null
    Assert-True ((Invoke-Git $clone @('status', '--short')) -eq '') 'The lifeline checkout should leave a clean status.'
    Invoke-Git $clone @('switch', '--quiet', 'vm-dev01-work') | Out-Null
    Assert-Slim $clone 'back on the work branch'

    # An uncommitted edit in a left-out folder is kept, the command still succeeds, and reapply finishes after it's discarded.
    $dirty = Join-Path $work 'dirty'
    Invoke-Git $work @('clone', '--quiet', $origin, $dirty) | Out-Null
    Add-Line (Join-Path $dirty 'docs/inner/file.txt') 'student edit'
    $output = Invoke-Git $dirty (@('sparse-checkout', 'set', '--no-cone') + $patterns)
    Assert-True ($output -match 'left despite sparse patterns') "Git should warn about the edited left-out file: $output"
    Assert-True ((Get-Content -Raw (Join-Path $dirty 'docs/inner/file.txt')) -match 'student edit') 'The edited file must stay.'
    Invoke-Git $dirty @('checkout', '--quiet', '--', 'docs/inner/file.txt') | Out-Null
    Invoke-Git $dirty @('sparse-checkout', 'reapply') | Out-Null
    Assert-Slim $dirty 'after reapply'

    Write-Output "PASS: $passed sparse checkout checks (local repositories only, no Azure calls)."
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
