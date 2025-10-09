# This is a script to build, run version, pack and push a NuGet package to a NuGet feed.
# - Default path for this script is: projectRoot/Properties/Scripts/nuget-pushed-package.ps1
#   - If you move this script, you need to change the path to the config file

# Parameters:
# - None, no addtional action required, run in default mode (build, test, version (develop), tag, pack, push)
# - IsRelease: if set to $true, the script will run in release mode (build, test, version (release), tag, pack, push)
# - PushNuGet: if set to $true, the script will push the package to the NuGet feed (default: $false, only pack the package)
param (
    [switch]$IsRelease = $false,
    [switch]$PushNuGet = $false
)

# Stop on errors
$ErrorActionPreference = "Stop"

# Prerequires: load configuration from ./nuget-config.json file
$configFilePath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "nuget-config.json"
if (-Not (Test-Path $configFilePath)) {
    Write-Error "Configuration file not found: $configFilePath"
    exit 1
}
$config = Get-Content $configFilePath | ConvertFrom-Json
$projectRoot = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) $config.rootRelativePath
$projectName = $config.projectName
$projectFilePath = Join-Path $projectRoot "$projectName.csproj"
$tagPrefix = $config.tagPrefix
$nugetSource = $config.nugetSource

# Step 0: Validate project file path and restore dependencies
Write-Host "Step 0: Validating project file and restoring dependencies..."
if (-Not (Test-Path $projectFilePath)) {
    Write-Error ".. Project file not found: $projectFilePath"
    exit 1
}
Write-Host ".. Restoring dependencies..."
dotnet restore $projectFilePath
if ($LASTEXITCODE -ne 0) {
    Write-Error ".... Restore failed. Please fix it before proceeding."
    exit 1
}
Write-Host ".. Dependencies restored."

# Step 1: Build the project (use configuration from IsRelease parameter)
Write-Host "Step 1: Building project..."
dotnet build $projectFilePath --configuration (if ($IsRelease) { "Release" } else { "Debug" })
if ($LASTEXITCODE -ne 0) {
    Write-Error ".. Build failed. Please fix it before proceeding."
    exit 1
}
Write-Host ".. Build succeeded."

# Step 2: Run test befor continue (if found test project)
$testProjectFilePath = Join-Path $projectRoot "$projectName.Tests\$projectName.Tests.csproj"
if (Test-Path $testProjectFilePath) {
    Write-Host "Step 2: Running tests..."
    dotnet test $testProjectFilePath --configuration Release
    if ($LASTEXITCODE -ne 0) {
        Write-Error ".. Tests failed. Please fix it before proceeding."
        exit 1
    }
    Write-Host ".. All tests passed."
} else {
    Write-Host "Step 2: No test project found, skipping tests."
}

# Step 3: Versioning develop/release (reading current version from project file) as x.y.z (release) or w.x.y-dev.z (develop), this will running `z` as auto-incremented number
Write-Host "Step 3: Versioning project..."
[xml]$csproj = Get-Content $projectFilePath
$versionNode = $csproj.Project.PropertyGroup.Version
if (-Not $versionNode) {
    Write-Error ".. Version node not found in project file. Please add a <Version>1.0.0</Version> node to the project file."
    exit 1
}
$currentVersion = $versionNode.'#text'
if ($IsRelease) {
    # Release versioning: x.y.z
    # - This will automatically drop dev suffix if exists
    #   - If it develop version, it will convert to release version by removing -dev.z suffix and not run increment on x.y.z
    #   - If it is already release version, it will just increment the patch version
    if ($currentVersion -notmatch '^\d+\.\d+\.\d+(-dev\.\d+)?$') {
        Write-Error ".. Current version '$currentVersion' is not in the format x.y.z or x.y.z-dev.z. Please fix it before proceeding."
        exit 1
    }
    $devSuffixPattern = '-dev\.\d+$'

    if ($currentVersion -match $devSuffixPattern) {
        # Convert develop to release by dropping the "-dev.N" suffix
        $newVersion = $currentVersion -replace $devSuffixPattern, ''
    }
    else {
        # Already release: increment patch (x.y.z -> x.y.(z+1))
        $v = [version]$currentVersion
        $newVersion = '{0}.{1}.{2}' -f $v.Major, $v.Minor, ($v.Build + 1)
    }

    $newVersion = $newVersion.Trim()
    
} else {
    # Develop versioning: w.x.y-dev.z
    if ($currentVersion -notmatch '^\d+\.\d+\.\d+-dev\.\d+$') {
        Write-Error ".. Current version '$currentVersion' is not in the format w.x.y-dev.z. Please fix it before proceeding."
        exit 1
    }
    $newVersion = $currentVersion -replace '(\d+)$', { [int]$args[0] + 1 }
}
Write-Host ".. Current version: $currentVersion"
Write-Host ".. New version: $newVersion"
$versionNode.'#text' = $newVersion
$csproj.Save($projectFilePath)
Write-Host ".. Project version updated."

# Step 4: Commit change and automatically create a git tag
Write-Host "Step 4: Committing changes and creating git tag..."
git add $projectFilePath
git commit -m "chore: Automatically bump version to $newVersion"
if ($LASTEXITCODE -ne 0) {
    Write-Error ".. Git commit failed. Please fix it before proceeding."
    exit 1
}
$tagName = "${tagPrefix}${newVersion}"
git tag $tagName
if ($LASTEXITCODE -ne 0) {
    Write-Error ".. Git tag creation failed. Please fix it before proceeding."
    exit 1
}
git push origin HEAD --tags
if ($LASTEXITCODE -ne 0) {
    Write-Error ".. Git push failed. Please fix it before proceeding."
    exit 1
}
Write-Host ".. Changes committed and tag '$tagName' created and pushed."

# Step 5: Pack the project to create a NuGet package
Write-Host "Step 5: Packing project to create NuGet package..."
$packageOutputPath = Join-Path $projectRoot "published"
if (-Not (Test-Path $packageOutputPath)) {
    New-Item -ItemType Directory -Path $packageOutputPath | Out-Null
}
dotnet pack $projectFilePath --configuration (if ($IsRelease) { "Release" } else { "Debug" }) --output $packageOutputPath
if ($LASTEXITCODE -ne 0) {
    Write-Error ".. Packing failed. Please fix it before proceeding."
    exit 1
}
Write-Host ".. Package created at: $packageOutputPath"

# Step 6: Push the package to NuGet feed (if PushNuGet parameter is set to $true), if in develop mode, it will also push debugging symbols package too.
if ($PushNuGet) {
    Write-Host "Step 6: Pushing package to NuGet feed..."
    $nupkgFiles = Get-ChildItem -Path $packageOutputPath -Filter "$projectName.*.nupkg" | Where-Object { $_.Name -notlike "*.symbols.nupkg" }
    foreach ($nupkgFile in $nupkgFiles) {
        Write-Host ".. Pushing package: $($nupkgFile.FullName)"
        dotnet nuget push $nupkgFile.FullName --source "$nugetSource"
        if ($LASTEXITCODE -ne 0) {
            Write-Error ".... Pushing package failed. Please fix it before proceeding."
            exit 1
        }
        Write-Host ".... Package pushed successfully."
    }

    if (-Not $IsRelease) {
        # In develop mode, also push symbols package if exists
        $symbolsNupkgFiles = Get-ChildItem -Path $packageOutputPath -Filter "$projectName.*.symbols.nupkg"
        foreach ($symbolsNupkgFile in $symbolsNupkgFiles) {
            Write-Host ".. Pushing symbols package: $($symbolsNupkgFile.FullName)"
            dotnet nuget push $symbolsNupkgFile.FullName --source "$nugetSource"
            if ($LASTEXITCODE -ne 0) {
                Write-Error ".... Pushing symbols package failed. Please fix it before proceeding."
                exit 1
            }
            Write-Host ".... Symbols package pushed successfully."
        }
    }
    Write-Host ".. All packages pushed successfully."
} else {
    Write-Host "Step 6: PushNuGet parameter not set. Skipping package push."
}

# Step 7: Summary
Write-Host "Step 7: Summary"
Write-Host ".. Project: $projectName"
Write-Host ".. Version: $newVersion"
Write-Host ".. Project file: $projectFilePath"
Write-Host ".. Package output path: $packageOutputPath"
Write-Host ".. NuGet source: $nugetSource"
if ($PushNuGet) {
    Write-Host ".. Package pushed to NuGet feed."
} else {
    Write-Host ".. Package not pushed to NuGet feed."
}
Write-Host "NuGet package process completed successfully."
# End of script
