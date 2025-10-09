# This script using for publish NuGet package for DMNSN.ProjectTemplates project.
# - Default path for this script is: projectRoot/scripts/templates/Nuget-Published.ps

# Parameters:
# - None, no addtional action required, run in default mode (export (build & pack), tag, push)
# - ExportOnly: if set to $true, the script will run in export only mode (export (build & pack) only, no tag, no push)

param (
    [switch]$ExportOnly = $false
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
# Validate nuget api key has exists if not ExportOnly
if (-Not $ExportOnly) {
    if (-Not $env:NUGET_API_KEY) {
        Write-Error "NUGET_API_KEY environment variable not set. Please set it before proceeding."
        exit 1
    }
}

# Step 1: Export project (build & pack)
Write-Host "Step 1: Exporting project..."
& $scriptExportPath
if ($LASTEXITCODE -ne 0) {
    Write-Error ".. Export failed. Please fix it before proceeding."
    exit 1
}
Write-Host ".. Export succeeded."
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
