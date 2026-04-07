# Nuget-Published.ps1
# Automates the DMNSN.ProjectTemplates publish pipeline in two modes.
#
# DEVELOP mode  (-Mode develop):
#   1. Resolves NuGet API key (parameter > NUGET_API_KEY env var). Stops if missing.
#   2. Computes next -dev.x version  (e.g. 10.0.2 -> 10.0.3-dev.1, 10.0.3-dev.1 -> 10.0.3-dev.2).
#   3. Exports & packs the template bundle.
#   4. Tags the dev version in git and pushes the tag.
#   5. Publishes the .nupkg to NuGet.org.
#
# RELEASE mode  (-Mode release):
#   1. Computes clean release version (strips -dev.x suffix).
#   2. Creates a release-{version} branch.
#   3. Exports & packs the template bundle with the release version.
#   4. Auto-generates a CHANGELOG.md entry from git log since the last release tag.
#   5. Commits templatepack.config.json + CHANGELOG.md to the release branch.
#   6. Pushes the branch and opens a PR targeting main via the gh CLI.
#   After the PR is merged a GitHub Actions workflow handles tagging + NuGet push.
#
# Parameters:
#   -Mode          develop | release  (required)
#   -NuGetApiKey   Override for the NUGET_API_KEY env var  (develop mode)
#   -Version       Override the computed version
#   -CommitMessage Custom release-branch commit message. Supports {version} and {tag}.
#   -PrTitle       Custom PR title  (release mode)

param (
    [Parameter(Mandatory)]
    [ValidateSet('develop', 'release')]
    [string]$Mode,

    # NuGet API key. Falls back to $env:NUGET_API_KEY when not provided.
    [string]$NuGetApiKey,

    # Override the computed version (both modes).
    [string]$Version,

    # Release-branch commit message. Supports {version} and {tag}.
    [string]$CommitMessage = "chore: release {tag}",

    # PR title override (release mode).
    [string]$PrTitle
)

$ErrorActionPreference = "Stop"

$projectName         = "DMNSN.ProjectTemplates"
$tagPrefix           = "v"
$nugetSource         = "https://api.nuget.org/v3/index.json"
$defaultBranch       = "main"
$projectRoot         = (Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "../../")).Path
$scriptExportPath    = Join-Path $projectRoot "scripts/templates/Export-DotnetCliTemplate.ps1"
$aggregateConfigPath = Join-Path $projectRoot "templatepack.config.json"
$changelogPath       = Join-Path $projectRoot "CHANGELOG.md"

# ── Helpers ────────────────────────────────────────────────────────────────────

function Assert-Command ([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Error "'$Name' command not found. Please install it and ensure it is on PATH."
        exit 1
    }
}

function Read-AggregateVersion {
    if (Test-Path $aggregateConfigPath) {
        return [string](Get-Content $aggregateConfigPath -Raw | ConvertFrom-Json).version
    }
    return "1.0.0"
}

# Computes the next -dev.x version from the current aggregate version.
#   10.0.2        → 10.0.3-dev.1  (new dev cycle: patch bumped, counter starts at 1)
#   10.0.3-dev.1  → 10.0.3-dev.2  (continuing dev: same patch, counter incremented)
function Get-DevVersion ([string]$Current) {
    if ($Current -match '^(\d+\.\d+\.)(\d+)(-dev\.(\d+))?') {
        $major_minor = $Matches[1]
        $patch       = [int]$Matches[2]
        if ($Matches[4]) {
            $devNum = [int]$Matches[4] + 1       # already in dev — increment counter
        } else {
            $patch++; $devNum = 1                # new dev cycle — bump patch, reset counter
        }
        return "{0}{1}-dev.{2}" -f $major_minor, $patch, $devNum
    }
    Write-Error "Cannot parse current version: $Current"; exit 1
}

# Strips the -dev.x suffix to produce a clean release version.
#   10.0.3-dev.5  → 10.0.3
#   10.0.3        → 10.0.3  (already clean)
function Get-ReleaseVersion ([string]$Current) {
    return ($Current -replace '-dev\.\d+$', '')
}

# Generates a Keep-a-Changelog-style entry from commits since the last release tag.
function New-ChangelogEntry ([string]$ReleaseVersion) {
    $date    = Get-Date -Format "yyyy-MM-dd"
    $lastTag = git tag --sort=-version:refname 2>$null |
                 Where-Object { $_ -match "^${tagPrefix}\d+\.\d+\.\d+$" } |
                 Select-Object -First 1
    $logArgs = if ($lastTag) { @("$lastTag..HEAD") } else { @() }
    $commits = git log @logArgs --pretty=format:"- %s (%h)" --no-merges 2>$null
    $body    = if ($commits) { $commits -join "`n" } else { "- No notable changes." }
    return "## [$ReleaseVersion] - $date`n`n$body"
}

# Prepends a new entry to CHANGELOG.md (creates the file if missing).
function Update-Changelog ([string]$Entry) {
    if (Test-Path $changelogPath) {
        $existing = Get-Content $changelogPath -Raw
        $updated  = $existing -replace '(?s)(# Changelog\r?\n\r?\n)', "`$1$Entry`n`n"
        Set-Content $changelogPath -Value $updated -Encoding UTF8 -NoNewline
    } else {
        Set-Content $changelogPath -Value "# Changelog`n`n$Entry`n" -Encoding UTF8 -NoNewline
    }
}

function Invoke-Export ([string]$ExportVersion) {
    Write-Host "  Running export (version: $ExportVersion)..." -ForegroundColor DarkGray
    & $scriptExportPath -Version $ExportVersion
    if ($LASTEXITCODE -ne 0) { Write-Error "Export failed."; exit 1 }
}

function Get-ExportedPackage ([string]$PackageVersion) {
    $pkg = Get-ChildItem (Join-Path $projectRoot "artifacts") -Filter "$projectName.$PackageVersion.nupkg" |
             Select-Object -First 1
    if (-not $pkg) { Write-Error "Package not found: $projectName.$PackageVersion.nupkg"; exit 1 }
    return $pkg
}

# ── Step 0: Pre-flight ─────────────────────────────────────────────────────────

Write-Host "Step 0: Pre-flight checks..." -ForegroundColor Cyan
if (-not (Test-Path $scriptExportPath)) { Write-Error "Export script not found: $scriptExportPath"; exit 1 }
Assert-Command "git"
if ($Mode -eq 'release') { Assert-Command "gh" }

# ── DEVELOP mode ───────────────────────────────────────────────────────────────

if ($Mode -eq 'develop') {
    Write-Host "Mode: DEVELOP" -ForegroundColor Yellow

    # Resolve NuGet API key (argument → env var)
    $apiKey = if ($NuGetApiKey) { $NuGetApiKey } else { $env:NUGET_API_KEY }
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Error "NuGet API key not found. Set the NUGET_API_KEY environment variable or pass -NuGetApiKey."
        exit 1
    }
    Write-Host "  NuGet API key resolved." -ForegroundColor DarkGray

    # Compute dev version
    $currentVersion = Read-AggregateVersion
    $devVersion     = if ($Version) { $Version } else { Get-DevVersion -Current $currentVersion }
    Write-Host "  Version: $currentVersion -> $devVersion" -ForegroundColor Green

    # Step 1: Export
    Write-Host "`nStep 1: Exporting templates..." -ForegroundColor Cyan
    Invoke-Export -ExportVersion $devVersion

    # Step 2: Tag dev version
    Write-Host "`nStep 2: Tagging dev version in git..." -ForegroundColor Cyan
    $tagName = "${tagPrefix}${devVersion}"
    git tag $tagName
    if ($LASTEXITCODE -ne 0) { Write-Error "git tag failed."; exit 1 }
    git push origin $tagName
    if ($LASTEXITCODE -ne 0) { Write-Error "git push tag failed."; exit 1 }
    Write-Host "  Tagged and pushed: $tagName" -ForegroundColor Green

    # Step 3: Publish to NuGet
    Write-Host "`nStep 3: Publishing to NuGet..." -ForegroundColor Cyan
    $pkg = Get-ExportedPackage -PackageVersion $devVersion
    dotnet nuget push $pkg.FullName --source $nugetSource --api-key $apiKey
    if ($LASTEXITCODE -ne 0) { Write-Error "NuGet push failed."; exit 1 }
    Write-Host "  Package published: $($pkg.Name)" -ForegroundColor Green

    Write-Host "`n✅ Develop publish complete. Version: $devVersion" -ForegroundColor Cyan
    exit 0
}

# ── RELEASE mode ───────────────────────────────────────────────────────────────

if ($Mode -eq 'release') {
    Write-Host "Mode: RELEASE" -ForegroundColor Magenta

    # Compute release version
    $currentVersion = Read-AggregateVersion
    $releaseVersion = if ($Version) { $Version } else { Get-ReleaseVersion -Current $currentVersion }
    $branchName     = "release-$releaseVersion"
    $tagName        = "${tagPrefix}${releaseVersion}"
    Write-Host "  Version: $currentVersion -> $releaseVersion" -ForegroundColor Green
    Write-Host "  Branch : $branchName" -ForegroundColor DarkGray

    # Guard: clean working tree
    $dirty = git status --porcelain 2>$null
    if ($dirty) {
        Write-Error "Working tree is not clean. Commit or stash all changes before releasing."
        exit 1
    }

    # Guard: tag must not already exist
    if (git tag -l $tagName 2>$null) {
        Write-Error "Tag $tagName already exists. This version has already been released."
        exit 1
    }

    # Step 1: Create release branch
    Write-Host "`nStep 1: Creating branch '$branchName'..." -ForegroundColor Cyan
    git checkout -b $branchName
    if ($LASTEXITCODE -ne 0) { Write-Error "git checkout -b failed."; exit 1 }

    # Step 2: Export with release version
    Write-Host "`nStep 2: Exporting templates (version: $releaseVersion)..." -ForegroundColor Cyan
    Invoke-Export -ExportVersion $releaseVersion

    # Step 3: Generate changelog entry
    Write-Host "`nStep 3: Generating changelog..." -ForegroundColor Cyan
    $changelogEntry = New-ChangelogEntry -ReleaseVersion $releaseVersion
    Update-Changelog -Entry $changelogEntry
    Write-Host "  CHANGELOG.md updated." -ForegroundColor Green

    # Step 4: Commit to release branch
    Write-Host "`nStep 4: Committing release files..." -ForegroundColor Cyan
    git add -- $aggregateConfigPath $changelogPath
    if ($LASTEXITCODE -ne 0) { Write-Error "git add failed."; exit 1 }
    $finalMessage = ($CommitMessage).Replace('{version}', $releaseVersion).Replace('{tag}', $tagName)
    git commit -m $finalMessage --no-verify
    if ($LASTEXITCODE -ne 0) { Write-Error "git commit failed."; exit 1 }
    Write-Host "  Committed: $finalMessage" -ForegroundColor DarkGray

    # Step 5: Push branch
    Write-Host "`nStep 5: Pushing branch '$branchName'..." -ForegroundColor Cyan
    git push origin $branchName
    if ($LASTEXITCODE -ne 0) { Write-Error "git push failed."; exit 1 }
    Write-Host "  Branch pushed." -ForegroundColor Green

    # Step 6: Create PR via gh CLI
    Write-Host "`nStep 6: Creating pull request..." -ForegroundColor Cyan
    $finalPrTitle = if ($PrTitle) { $PrTitle } else { "Release $tagName" }
    $prBody = @"
## Release $tagName

$changelogEntry

---
_Merging this PR will automatically tag ``$tagName`` and publish ``$projectName.$releaseVersion.nupkg`` to NuGet._
"@
    gh pr create `
        --base $defaultBranch `
        --head $branchName `
        --title $finalPrTitle `
        --body $prBody
    if ($LASTEXITCODE -ne 0) { Write-Error "gh pr create failed."; exit 1 }

    Write-Host "`n✅ Release PR created for version $releaseVersion." -ForegroundColor Magenta
    Write-Host "   After the PR is merged, GitHub Actions will:" -ForegroundColor DarkGray
    Write-Host "     1. Tag $tagName and push to origin" -ForegroundColor DarkGray
    Write-Host "     2. Pack and publish $projectName.$releaseVersion.nupkg to NuGet" -ForegroundColor DarkGray
    exit 0
}
# End of script
