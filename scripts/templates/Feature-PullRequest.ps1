# Feature-PullRequest.ps1
# Creates a pull request from the current feature branch into develop.
#
# Version bump behaviour (applied to the version in templatepack.config.json):
#   Default            — bump PATCH,              e.g. 10.0.2 → 10.0.3
#   -BumpMinor         — bump MINOR, reset patch,  e.g. 10.0.2 → 10.1.0
#   -BumpMajor         — bump MAJOR, reset minor+patch, e.g. 10.0.2 → 11.0.0
#
# If the current version already has a pre-release suffix (-dev.x) it is
# stripped before bumping so the stored version is always a clean semver.
#
# What this script does:
#   1. Validates the working branch is a feature/* branch.
#   2. Validates git is clean (no uncommitted changes) before touching anything.
#   3. Computes the new version and writes it to templatepack.config.json.
#   4. Commits the version bump on the feature branch.
#   5. Pushes the branch to origin.
#   6. Opens a PR targeting develop via the gh CLI.
#
# Parameters:
#   -BumpMinor      Bump the minor version component (resets patch to 0).
#   -BumpMajor      Bump the major version component (resets minor and patch to 0).
#   -Version        Explicit target version, skips auto-bump entirely.
#   -Title          PR title. Defaults to "feat: <branch-name> → <version>".
#   -Body           PR body text. Supports {version}, {branch}, {tag} placeholders.
#   -Draft          Open the PR as a draft.

param (
    [switch]$BumpMinor,
    [switch]$BumpMajor,

    # Explicit version override (skips auto-bump).
    [string]$Version,

    # PR title. Supports {version}, {branch}, {tag}.
    [string]$Title,

    # PR body. Supports {version}, {branch}, {tag}.
    [string]$Body,

    # Open the PR as a draft.
    [switch]$Draft
)

$ErrorActionPreference = "Stop"

$targetBranch        = "develop"
$tagPrefix           = "v"
$projectRoot         = (Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "../../")).Path
$aggregateConfigPath = Join-Path $projectRoot "templatepack.config.json"

# ── Helpers ────────────────────────────────────────────────────────────────────

function Assert-Command ([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Error "'$Name' command not found. Please install it and ensure it is on PATH."
        exit 1
    }
}

# Reads the version from templatepack.config.json, stripping any pre-release suffix.
function Read-CleanVersion {
    if (-not (Test-Path $aggregateConfigPath)) {
        Write-Error "templatepack.config.json not found at: $aggregateConfigPath"
        exit 1
    }
    $raw = [string](Get-Content $aggregateConfigPath -Raw | ConvertFrom-Json).version
    # Strip pre-release suffix (e.g. -dev.3) so we always bump from a clean base.
    return ($raw -replace '-[A-Za-z0-9.]+$', '')
}

# Bumps a clean semver string according to the selected mode.
function Invoke-VersionBump ([string]$Current) {
    if ($Current -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
        Write-Error "Cannot parse version '$Current'. Expected Major.Minor.Patch format."
        exit 1
    }
    [int]$major = $Matches[1]
    [int]$minor = $Matches[2]
    [int]$patch = $Matches[3]

    if ($BumpMajor) { $major++; $minor = 0; $patch = 0 }
    elseif ($BumpMinor) { $minor++; $patch = 0 }
    else { $patch++ }

    return "$major.$minor.$patch"
}

# Writes the new version back into templatepack.config.json preserving all other fields.
function Set-AggregateVersion ([string]$NewVersion) {
    $cfg = Get-Content $aggregateConfigPath -Raw | ConvertFrom-Json
    $cfg.version = $NewVersion
    $cfg | ConvertTo-Json -Depth 10 | Set-Content $aggregateConfigPath -Encoding UTF8 -NoNewline
}

function Expand-Placeholders ([string]$Template, [string]$Ver, [string]$Branch) {
    return $Template `
        -replace '\{version\}', $Ver `
        -replace '\{branch\}',  $Branch `
        -replace '\{tag\}',     "${tagPrefix}${Ver}"
}

# ── Step 0: Pre-flight ─────────────────────────────────────────────────────────

Write-Host "Step 0: Pre-flight checks..." -ForegroundColor Cyan
Assert-Command "git"
Assert-Command "gh"

$currentBranch = git branch --show-current 2>$null
if ([string]::IsNullOrWhiteSpace($currentBranch)) {
    Write-Error "Cannot determine current branch. Are you in a detached HEAD state?"
    exit 1
}

if (-not ($currentBranch -match '^(features?|feat|feature)/')) {
    Write-Error "Current branch '$currentBranch' is not a feature branch (expected prefix: feature/ or features/)."
    exit 1
}
Write-Host "  Branch : $currentBranch" -ForegroundColor DarkGray

# Ensure working tree is clean — version bump commit must be the only change.
$dirty = git status --porcelain 2>$null
if ($dirty) {
    Write-Error "Working tree is not clean. Commit or stash all changes before creating a feature PR."
    exit 1
}

# Ensure target branch exists on origin.
git ls-remote --exit-code origin $targetBranch > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Target branch '$targetBranch' not found on origin."
    exit 1
}

# ── Step 1: Compute new version ────────────────────────────────────────────────

Write-Host "`nStep 1: Computing version bump..." -ForegroundColor Cyan
$currentClean = Read-CleanVersion

if ($Version) {
    $newVersion = $Version
    Write-Host "  Version (override): $newVersion" -ForegroundColor Yellow
} else {
    $bumpType   = if ($BumpMajor) { "MAJOR" } elseif ($BumpMinor) { "MINOR" } else { "PATCH" }
    $newVersion = Invoke-VersionBump -Current $currentClean
    Write-Host "  Bump type : $bumpType" -ForegroundColor DarkGray
    Write-Host "  Version   : $currentClean → $newVersion" -ForegroundColor Green
}

# ── Step 2: Write version & commit ────────────────────────────────────────────

Write-Host "`nStep 2: Writing version to templatepack.config.json..." -ForegroundColor Cyan
Set-AggregateVersion -NewVersion $newVersion

git add -- $aggregateConfigPath
if ($LASTEXITCODE -ne 0) { Write-Error "git add failed."; exit 1 }

$commitMsg = "chore: bump version to $newVersion for $currentBranch"
git commit -m $commitMsg --no-verify
if ($LASTEXITCODE -ne 0) { Write-Error "git commit failed."; exit 1 }
Write-Host "  Committed: $commitMsg" -ForegroundColor DarkGray

# ── Step 3: Push branch ────────────────────────────────────────────────────────

Write-Host "`nStep 3: Pushing branch '$currentBranch'..." -ForegroundColor Cyan
git push origin $currentBranch
if ($LASTEXITCODE -ne 0) { Write-Error "git push failed."; exit 1 }
Write-Host "  Branch pushed." -ForegroundColor Green

# ── Step 4: Create PR ─────────────────────────────────────────────────────────

Write-Host "`nStep 4: Creating pull request → $targetBranch..." -ForegroundColor Cyan

$defaultTitle = "feat: {branch} → v{version}"
$finalTitle   = Expand-Placeholders -Template (if ($Title) { $Title } else { $defaultTitle }) `
                                    -Ver $newVersion -Branch $currentBranch

$defaultBody = @"
## Feature: {branch}

**Target version:** \`{version}\`

### Changes
<!-- Describe what this feature does -->

---
_Version \`{version}\` will be locked once this PR is merged to \`develop\`._
_A subsequent release PR will promote it to \`main\` and publish to NuGet._
"@
$finalBody = Expand-Placeholders -Template (if ($Body) { $Body } else { $defaultBody }) `
                                 -Ver $newVersion -Branch $currentBranch

$prArgs = @(
    "pr", "create",
    "--base",  $targetBranch,
    "--head",  $currentBranch,
    "--title", $finalTitle,
    "--body",  $finalBody
)
if ($Draft) { $prArgs += "--draft" }

gh @prArgs
if ($LASTEXITCODE -ne 0) { Write-Error "gh pr create failed."; exit 1 }

Write-Host "`n✅ Feature PR created." -ForegroundColor Green
Write-Host "   Branch  : $currentBranch → $targetBranch" -ForegroundColor DarkGray
Write-Host "   Version : $newVersion  (locked on merge)" -ForegroundColor DarkGray
# End of script
