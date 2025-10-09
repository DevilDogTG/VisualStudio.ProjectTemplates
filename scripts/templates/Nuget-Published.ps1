# This script using for publish NuGet package for DMNSN.ProjectTemplates project.
# - Default path for this script is: projectRoot/scripts/templates/Nuget-Published.ps

# Parameters:
# - Default: export (build & pack), tag, push to NuGet
# - ExportOnly: export only, no tag, no NuGet push
# - AutoCommit: after export, auto-commit aggregate changes when version bumped or new template added
# - AutoPush: push the auto-commit to upstream (only effective with -AutoCommit)
# - CommitMessage: custom commit message, supports {version} and {tag}

param (
    [switch]$ExportOnly = $false,
    # If set, automatically commit changes when version bumped or new template added
    [switch]$AutoCommit = $false,
    # If set, push the commit to the current upstream after committing
    [switch]$AutoPush = $false,
    # Optional commit message. Supports placeholders: {version}, {tag}
    [string]$CommitMessage
)

# Stop on errors
$ErrorActionPreference = "Stop"

# Configure parameters
$projectName = "DMNSN.ProjectTemplates"
$tagPrefix = "v"
$nugetSource = "https://api.nuget.org/v3/index.json"
$projectRoot = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "../../"
$scriptsRoot = Join-Path $projectRoot "scripts/templates"
$scriptExportPath = Join-Path $scriptsRoot "Export-DotnetCliTemplate.ps1"
${aggregateConfigPath} = Join-Path $projectRoot "templatepack.config.json"

# Step 0: Validate project root and export script path
Write-Host "Step 0: Validating project root and export script path..."
if (-Not (Test-Path $projectRoot)) {
    Write-Error "Project root not found: $projectRoot"
    exit 1
}
if (-Not (Test-Path $scriptExportPath)) {
    Write-Error "Export script not found: $scriptExportPath"
    exit 1
}
# Ensure git is available if auto commit/push requested
if ($AutoCommit -or $AutoPush) {
    git --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git is required for auto commit/push but was not found on PATH."
        exit 1
    }
}
# Validate nuget api key has exists if not ExportOnly
if (-Not $ExportOnly) {
    if (-Not $env:NUGET_API_KEY) {
        Write-Error "NUGET_API_KEY environment variable not set. Please set it before proceeding."
        exit 1
    }
}

# Load pre-export aggregate config snapshot (for change detection)
$preVersion = $null
$preTemplateKeys = @()
if (Test-Path ${aggregateConfigPath}) {
    try {
        $preCfg = Get-Content -Path ${aggregateConfigPath} -Raw | ConvertFrom-Json
        $preVersion = [string]$preCfg.version
        if ($preCfg.templates) {
            if ($preCfg.templates -is [hashtable]) {
                $preTemplateKeys = @($preCfg.templates.Keys)
            } else {
                $preTemplateKeys = @($preCfg.templates.PSObject.Properties.Name)
            }
        }
    } catch { }
}

# Step 1: Export project (build & pack)
Write-Host "Step 1: Exporting project..."
& $scriptExportPath
if ($LASTEXITCODE -ne 0) {
    Write-Error ".. Export failed. Please fix it before proceeding."
    exit 1
}
Write-Host ".. Export succeeded."

# Load post-export aggregate config snapshot
$postVersion = $null
$postTemplateKeys = @()
if (Test-Path ${aggregateConfigPath}) {
    try {
        $postCfg = Get-Content -Path ${aggregateConfigPath} -Raw | ConvertFrom-Json
        $postVersion = [string]$postCfg.version
        if ($postCfg.templates) {
            if ($postCfg.templates -is [hashtable]) {
                $postTemplateKeys = @($postCfg.templates.Keys)
            } else {
                $postTemplateKeys = @($postCfg.templates.PSObject.Properties.Name)
            }
        }
    } catch { }
}

# Determine if version bumped or new template added
$didVersionBump = $false
if ($preVersion -and $postVersion) { $didVersionBump = ($preVersion -ne $postVersion) }
$hasNewTemplate = $false
if ($postTemplateKeys.Count -gt 0) {
    $preSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($k in $preTemplateKeys) { [void]$preSet.Add([string]$k) }
    foreach ($k in $postTemplateKeys) { if (-not $preSet.Contains([string]$k)) { $hasNewTemplate = $true; break } }
}

# Optional: Auto commit and push changes to aggregate config if needed
if ($AutoCommit -and ($didVersionBump -or $hasNewTemplate)) {
    Write-Host "Step 1.1: Auto committing aggregate config changes..."
    # Stage only the aggregate config to avoid committing artifacts or unrelated changes
    if (Test-Path ${aggregateConfigPath}) {
        git add -- ${aggregateConfigPath}
        if ($LASTEXITCODE -ne 0) {
            Write-Error ".. Failed to stage ${aggregateConfigPath} for commit."
            exit 1
        }
    }
    # Skip commit if nothing to commit (e.g., file unchanged)
    git diff --cached --quiet
    $hasStagedChanges = ($LASTEXITCODE -ne 0)
    if (-not $hasStagedChanges) {
        Write-Host ".. No staged changes to commit. Skipping commit/push."
    } else {
        $finalMessage = $CommitMessage
        if ([string]::IsNullOrWhiteSpace($finalMessage)) {
            $finalMessage = "chore(templates): export ${projectName} ${postVersion}"
        }
        # Token replacements
        $finalMessage = $finalMessage.Replace('{version}', [string]$postVersion)
        $tagPreview = if ($postVersion) { "${tagPrefix}${postVersion}" } else { $null }
        if ($tagPreview) { $finalMessage = $finalMessage.Replace('{tag}', $tagPreview) }

        git commit -m $finalMessage --no-verify
        if ($LASTEXITCODE -ne 0) {
            Write-Error ".. Commit failed."
            exit 1
        }
        Write-Host ".. Commit created: $finalMessage"

        if ($AutoPush) {
            Write-Host ".. Pushing commit to upstream..."
            git push
            if ($LASTEXITCODE -ne 0) {
                Write-Error ".. Pushing commit failed."
                exit 1
            }
            Write-Host ".. Commit pushed."
        }
    }
}
# Get the version from the exported package
$exportedPackagePath = Join-Path $projectRoot "artifacts"
$exportedPackage = Get-ChildItem -Path $exportedPackagePath -Filter "$projectName*.nupkg" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-Not $exportedPackage) {
    Write-Error ".. Exported package not found in $exportedPackagePath"
    exit 1
}
$versionPattern = [regex]::Escape($projectName) + "\.(\d+\.\d+\.\d+(-[A-Za-z0-9]+)?)\.nupkg"
if ($exportedPackage.Name -match $versionPattern) {
    $packageVersion = $matches[1]
    Write-Host ".. Exported package version: $packageVersion"
} else {
    Write-Error ".. Unable to extract version from package name: $($exportedPackage.Name)"
    exit 1
}
Write-Host ".. Exported package path: $($exportedPackage.FullName)"
if ($ExportOnly) {
    Write-Host "ExportOnly flag is set. Skipping tagging and pushing steps."
    exit 0
}

# Step 2: Tag the version in git
Write-Host "Step 2: Tagging version in git..."
$tagName = "${tagPrefix}${packageVersion}"
git tag $tagName
if ($LASTEXITCODE -ne 0) {
    Write-Error ".. Tagging failed. Please fix it before proceeding."
    exit 1
}
git push origin $tagName
if ($LASTEXITCODE -ne 0) {
    Write-Error ".. Pushing tag failed. Please fix it before proceeding."
    exit 1
}
Write-Host ".. Tagged and pushed version: $tagName"

# Step 3: Push the package to NuGet feed
Write-Host "Step 3: Pushing package to NuGet feed..."
dotnet nuget push $exportedPackage.FullName --source $nugetSource --api-key $env:NUGET_API_KEY
if ($LASTEXITCODE -ne 0) {
    Write-Error ".. Pushing package failed. Please fix it before proceeding."
    exit 1
}
Write-Host ".. Package pushed successfully."

# Step 4: Summary
Write-Host "Step 4: Summary"
Write-Host ".. Exported package: $($exportedPackage.FullName)"
Write-Host ".. Tagged version: $tagName"
Write-Host ".. Pushed to NuGet source: $nugetSource"
Write-Host "NuGet package publishing process completed successfully."
# End of script
