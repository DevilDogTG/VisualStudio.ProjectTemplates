param (
    [string[]]$Projects,
    [string]$Version,
    [switch]$DryRun,
    [switch]$NoPack,
    [switch]$InstallLatestPackage,
    [string]$TemplatesPath = "output",
    [string]$PackagesPath = "artifacts",
    [string]$LogPath,
    [string]$PackageId = "DMNSN.ProjectTemplates",
    [string]$PackageTitle,
    [string]$PackageDescription,
    [string]$AggregateConfigPath = "templatepack.config.json"
)

$ErrorActionPreference = "Stop"

function Log {
    param (
        [string]$Message,
        [string]$Color = "Gray"
    )

    if ($Color) {
        Write-Host $Message -ForegroundColor $Color
    } else {
        Write-Host $Message
    }

    if ($script:LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $script:LogFile -Value ("[{0}] {1}" -f $timestamp, $Message)
    }
}

function Map-LanguageTag {
    param ([string]$Tag)

    if (-not $Tag) { return "C#" }

    switch ($Tag.ToLowerInvariant()) {
        "csharp" { return "C#" }
        "fsharp" { return "F#" }
        "vb" { return "VB" }
        default { return $Tag }
    }
}

function Get-RelativePath {
    param (
        [string]$BasePath,
        [string]$TargetPath
    )

    return [System.IO.Path]::GetRelativePath($BasePath, $TargetPath)
}

function Get-SafeName {
    param (
        [string]$Name,
        [string]$Fallback
    )

    $candidate = if ([string]::IsNullOrWhiteSpace($Name)) { $Fallback } else { $Name }
    $candidate = $candidate.Trim()
    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    $builder = New-Object System.Text.StringBuilder
    foreach ($ch in $candidate.ToCharArray()) {
        if ($invalid -contains $ch) {
            [void]$builder.Append('-')
        } elseif ($ch -eq ' ') {
            [void]$builder.Append('-')
        } else {
            [void]$builder.Append($ch)
        }
    }
    $result = $builder.ToString()
    if ([string]::IsNullOrWhiteSpace($result)) { return $Fallback }
    return $result
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -Parent (Split-Path -Parent $scriptDir)
$srcPath = Join-Path $RootPath "src"

if (-not (Test-Path $srcPath)) {
    throw "Unable to locate src directory at $srcPath"
}

## Default behavior: if -Projects is omitted, all templates are processed.

function Resolve-RootedPath {
    param (
        [string]$Base,
        [string]$PathValue
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $null
    }

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return (Resolve-Path -Path $PathValue).ProviderPath
    }

    return (Join-Path $Base $PathValue)
}

$TemplatesFullPath = Resolve-RootedPath -Base $RootPath -PathValue $TemplatesPath
$PackagesFullPath = Resolve-RootedPath -Base $RootPath -PathValue $PackagesPath

function Get-LatestPackageInfo {
    param (
        [string]$PackagesRoot,
        [string]$Identity
    )

    if ([string]::IsNullOrWhiteSpace($PackagesRoot) -or -not (Test-Path $PackagesRoot)) {
        return $null
    }

    $regex = '^{0}\.(?<version>.+)\.nupkg$' -f ([regex]::Escape($Identity))
    $candidates = Get-ChildItem -Path $PackagesRoot -Filter '*.nupkg' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $match = [regex]::Match($_.Name, $regex)
        if ($match.Success) {
            $versionText = $match.Groups['version'].Value
            $parsedVersion = $null
            $hasVersion = [System.Version]::TryParse($versionText, [ref]$parsedVersion)
            [pscustomobject]@{
                File = $_
                VersionText = $versionText
                Version = if ($hasVersion) { $parsedVersion } else { $null }
                HasVersion = $hasVersion
            }
        }
    }

    if (-not $candidates) {
        return $null
    }

    $ordered = $candidates | Sort-Object -Property @{ Expression = { $_.HasVersion }; Descending = $true }, @{ Expression = { $_.Version }; Descending = $true }, @{ Expression = { $_.VersionText }; Descending = $true }
    return $ordered | Select-Object -First 1
}

$script:LogFile = $null
if ($LogPath) {
    $logFullPath = Resolve-RootedPath -Base $RootPath -PathValue $LogPath
    $logDir = Split-Path -Parent $logFullPath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    }
    if (-not (Test-Path $logFullPath)) {
        New-Item -ItemType File -Force -Path $logFullPath | Out-Null
    }
    $script:LogFile = $logFullPath
} else {
    $logDir = Join-Path $RootPath "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    }
    $defaultLog = Join-Path $logDir ("export-dotnetcli-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
    New-Item -ItemType File -Force -Path $defaultLog | Out-Null
    $script:LogFile = $defaultLog
}

if (-not $DryRun) {
    if (-not (Test-Path $TemplatesFullPath)) {
        New-Item -ItemType Directory -Force -Path $TemplatesFullPath | Out-Null
    }
    if (-not $NoPack -and $PackagesFullPath -and -not (Test-Path $PackagesFullPath)) {
        New-Item -ItemType Directory -Force -Path $PackagesFullPath | Out-Null
    }
} else {
    Log "Dry run enabled. No files will be written." "DarkGray"
}

$projectSet = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)
$projectDirs = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]

function Add-ProjectDir {
    param ([string]$Candidate)

    $resolved = $null
    if (Test-Path $Candidate) {
        $resolved = (Resolve-Path -Path $Candidate).ProviderPath
    } else {
        $combined = Join-Path $srcPath $Candidate
        if (Test-Path $combined) {
            $resolved = (Resolve-Path -Path $combined).ProviderPath
        }
    }

    if (-not $resolved) {
        throw "Project path not found: $Candidate"
    }

    $dirInfo = Get-Item -Path $resolved
    if (-not $dirInfo.PSIsContainer) {
        throw "Path is not a directory: $resolved"
    }

    if ($projectSet.Add($dirInfo.FullName)) {
        $projectDirs.Add($dirInfo)
    }
}

if ($Projects) {
    foreach ($proj in $Projects) {
        Add-ProjectDir $proj
    }
}

if ($projectDirs.Count -eq 0) {
    # No -Projects specified; include all projects by default
    Get-ChildItem -Path $srcPath -Directory | ForEach-Object { Add-ProjectDir $_.FullName }
}


$templateSummaries = New-Object System.Collections.Generic.List[pscustomobject]
$aggregateTags = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)
$null = $aggregateTags.Add("dotnet-new")
$null = $aggregateTags.Add("template")
$aggregateAuthors = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)

$excludedDirectories = @("bin", "obj", "logs", ".vs", ".git", "artifacts", "TestResults")
$excludedFileNames = @(".template.hash", "template.config.json")
$excludedExtensions = @(".user")

# Compute project content hash for change detection (aggregate version bumping)
function Get-ProjectContentHash {
    param([string]$ProjectPath)

    $excludedDirs = @("bin", "obj", "logs", ".vs", ".git", "artifacts", "TestResults")
    $excludedNames = @("template.config.json", ".template.hash")
    $excludedExts = @(".zip", ".vstemplate", ".user", ".suo")

    $files = Get-ChildItem -Path $ProjectPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $relativePath = Get-RelativePath $ProjectPath $_.FullName
        if (-not $relativePath) { return $false }
        $parts = $relativePath -split "[\\/]"
        $inExcludedDir = ($parts | Where-Object { $excludedDirs -contains $_ }).Count -gt 0
        $isExcludedName = $excludedNames -contains $_.Name
        $isExcludedExt = $excludedExts -contains ($_.Extension.ToLower())
        -not ($inExcludedDir -or $isExcludedName -or $isExcludedExt)
    }

    $hashEntries = @()
    foreach ($file in ($files | Sort-Object FullName)) {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) { $content = "" }
        $normalized = ($content -replace "`r`n", "`n") -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        $normalizedText = ($normalized -join "`n")
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalizedText)
        $fileHashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
        $fileHash = [System.BitConverter]::ToString($fileHashBytes).Replace('-', '').ToLower()
        $rel = (Get-RelativePath $ProjectPath $file.FullName).Replace('\\','/').ToLower()
        $hashEntries += "${rel}:${fileHash}"
    }

    $combined = [System.Text.Encoding]::UTF8.GetBytes(($hashEntries -join "`n"))
    $finalBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($combined)
    return [System.BitConverter]::ToString($finalBytes).Replace('-', '').ToLower()
}

# Load aggregate config (running version + per-template hash)
$aggregateConfigFullPath = Resolve-RootedPath -Base $RootPath -PathValue $AggregateConfigPath
$aggregateConfig = $null
if (Test-Path $aggregateConfigFullPath) {
    try { $aggregateConfig = Get-Content -Path $aggregateConfigFullPath -Raw | ConvertFrom-Json } catch { $aggregateConfig = $null }
}
if (-not $aggregateConfig) {
    $aggregateConfig = [ordered]@{ version = "1.0.0"; packageId = $PackageId; templates = @{} }
}

# Ensure templates map is a hashtable for safe indexing
if ($aggregateConfig.templates) {
    if (-not ($aggregateConfig.templates -is [hashtable])) {
        $t = @{}
        foreach ($p in $aggregateConfig.templates.PSObject.Properties) { $t[$p.Name] = $p.Value }
        $aggregateConfig.templates = $t
    }
} else {
    $aggregateConfig.templates = @{}
}

$anyTemplateChanged = $false
$currentHashes = @{}

foreach ($projectDir in $projectDirs | Sort-Object FullName) {
    $projectPath = $projectDir.FullName
    $projectName = $projectDir.Name
    Log ("⚙ Processing '{0}'..." -f $projectName) "Cyan"

    $configPath = Join-Path $projectPath "template.config.json"
    if (-not (Test-Path $configPath)) {
        Log "  Skipping: template.config.json not found" "Yellow"
        continue
    }

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    if (-not $config.identity) { throw "Missing identity in $configPath" }
    if (-not $config.shortName) { throw "Missing shortName in $configPath" }

    $packageVersion = if ($config.version) { $config.version } else { "1.0.0" }
    $language = Map-LanguageTag $config.languageTag

    $classifications = New-Object System.Collections.Generic.List[string]
    # if ($config.category) { $classifications.Add([string]$config.category) }
    if ($config.tags) {
        foreach ($tag in $config.tags) {
            if ($tag) { $classifications.Add([string]$tag) }
        }
    }
    $classifications = $classifications | Sort-Object -Unique

    $csproj = Get-ChildItem -Path $projectPath -Filter "*.csproj" -File | Select-Object -First 1
    if (-not $csproj) {
        throw "Unable to locate .csproj file in $projectPath"
    }

    $sourceName = if ($config.defaultNamespace) { $config.defaultNamespace } else { [System.IO.Path]::GetFileNameWithoutExtension($csproj.Name) }
    $defaultName = $null
    if ($config.provideDefaultName -and $sourceName) {
        $defaultName = $sourceName.Split('.') | Select-Object -Last 1
    }

    $templateModel = [ordered]@{
        "`$schema" = "http://json.schemastore.org/template"
        author = $config.author
        classifications = @($classifications)
        name = $config.name
        identity = $config.identity
        shortName = $config.shortName
        description = $config.description
        sourceName = $sourceName
        preferNameDirectory = [bool]$config.createNewFolder
        tags = [ordered]@{
            language = $language
            type = "project"
        }
        primaryOutputs = @([ordered]@{ path = $csproj.Name })
    }

    if ($config.templateGroupIdentity) {
        $templateModel.groupIdentity = $config.templateGroupIdentity
    }

    if ($defaultName) {
        $templateModel.defaultName = $defaultName
    }

    $packageTags = @("dotnet-new", "template", $config.projectTypeTag) + @($config.tags)
    $packageTags = $packageTags | Where-Object { $_ } | Sort-Object -Unique

    $displayTags = $null
    $tagItems = @()
    foreach ($tag in @($config.tags)) {
        if (-not [string]::IsNullOrWhiteSpace($tag)) {
            $tagItems += [string]$tag
        }
    }
    if ($tagItems.Count -gt 0) {
        $displayTags = $tagItems -join ","
    }

    if ($config.name) {
        Log ("📋 Template Name: {0}" -f $config.name)
    }

    if ($config.author) {
        Log ("👤 Author: {0}" -f $config.author)
    }

    if ($packageVersion) {
        Log ("🔢 Version: {0}" -f $packageVersion)
    }

    if ($displayTags) {
        Log ("🏷️ Tags: {0}" -f $displayTags)
    }

    if ($config.category) {
        Log ("📂 Category: {0}" -f $config.category)
    }

    if ($config.projectType) {
        Log ("🎯 Project Type: {0}" -f $config.projectType)
    }

    $folderSafeName = Get-SafeName -Name $config.shortName -Fallback $config.identity
    $templateRoot = Join-Path $TemplatesFullPath $folderSafeName

    if (-not $DryRun) {
        if (Test-Path $templateRoot) {
            Remove-Item -Path $templateRoot -Recurse -Force
        }
        New-Item -ItemType Directory -Force -Path $templateRoot | Out-Null
    } else {
        Log "  Dry run: would prepare folder $templateRoot" "DarkGray"
    }

    $items = Get-ChildItem -Path $projectPath -Recurse -Force
    foreach ($item in $items) {
        $relative = Get-RelativePath $projectPath $item.FullName
        if (-not $relative -or $relative -eq '.') { continue }

        $segments = $relative -split "[\\/]"
        if ($segments | Where-Object { $excludedDirectories -contains $_ }) {
            continue
        }

        if (-not $item.PSIsContainer) {
            $fileName = $item.Name
            if ($excludedFileNames -contains $fileName) { continue }
            $ext = [System.IO.Path]::GetExtension($fileName)
            if ($ext -and ($excludedExtensions -contains $ext)) { continue }

            $destination = Join-Path $templateRoot $relative
            if (-not $DryRun) {
                $destDir = Split-Path -Parent $destination
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
                }
                Copy-Item -Path $item.FullName -Destination $destination -Force
            }
        }
    }

    $templateConfigDir = Join-Path $templateRoot ".template.config"
    $templateJsonPath = Join-Path $templateConfigDir "template.json"
    if ($config.icon) {
        $templateModel.icon = $config.icon
    }
    $templateJsonContent = ConvertTo-Json $templateModel -Depth 10

    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path $templateConfigDir | Out-Null
        Set-Content -Path $templateJsonPath -Value $templateJsonContent -Encoding UTF8
        Log "  Template folder ready at $templateRoot" "Green"
    } else {
        Log "  Dry run: would write template.json to $templateJsonPath" "DarkGray"
    }

    foreach ($tag in $packageTags) {
        $null = $aggregateTags.Add([string]$tag)
    }

    if ($config.author) {
        $null = $aggregateAuthors.Add([string]$config.author)
    }

    # Track content hash for aggregate version bump logic
    $currentHash = Get-ProjectContentHash -ProjectPath $projectPath
    $currentHashes[$config.identity] = $currentHash
    $previousHash = $null
    if ($aggregateConfig.templates.ContainsKey($config.identity)) {
        $previousHash = $aggregateConfig.templates[$config.identity].hash
    }
    if (-not $previousHash -or $previousHash -ne $currentHash) {
        $anyTemplateChanged = $true
    }

    [void]$templateSummaries.Add([pscustomobject]@{
        ProjectName = $projectName
        Identity = $config.identity
        TemplateName = $config.name
        TemplateRoot = $templateRoot
        FolderSafeName = $folderSafeName
        PackageVersion = $packageVersion
    })
}

$selectedTemplateCount = $templateSummaries.Count
if ($selectedTemplateCount -eq 0) {
    Log "No templates were processed successfully." "Yellow"
    return
}

$sortedTemplateSummaries = $templateSummaries | Sort-Object -Property @{ Expression = { $_.TemplateName }; Ascending = $true }, @{ Expression = { $_.ProjectName }; Ascending = $true }
$templateNames = @($sortedTemplateSummaries | ForEach-Object { $_.TemplateName } | Where-Object { $_ })

# Determine aggregated package version using running config
$currentAggregateVersion = if ($aggregateConfig.version) { [string]$aggregateConfig.version } else { "1.0.0" }
if ($Version) {
    $aggregatedVersion = $Version
    Log ("?? Aggregate package version (override): {0}" -f $aggregatedVersion)
} else {
    if ($anyTemplateChanged) {
        # bump patch version
        $vparts = ($currentAggregateVersion -split '\.')
        if ($vparts.Length -lt 3) { $vparts = @($vparts + (0..(2 - $vparts.Length) | ForEach-Object { '0' })) }
        $vparts[2] = [int]$vparts[2] + 1
        $aggregatedVersion = "{0}.{1}.{2}" -f $vparts[0], $vparts[1], $vparts[2]
        Log ("?? Aggregate version bumped: {0} -> {1}" -f $currentAggregateVersion, $aggregatedVersion) "Green"
    } else {
        $aggregatedVersion = $currentAggregateVersion
        Log ("?? Aggregate version unchanged: {0}" -f $aggregatedVersion) "DarkGray"
    }
}

$aggregateAuthorsList = if ($aggregateAuthors.Count -gt 0) { @($aggregateAuthors) | Sort-Object -Unique } else { @("Unknown") }
$aggregateTagsString = (@($aggregateTags) | Sort-Object -Unique) -join ";"

if ($NoPack) {
    Log "Skipping dotnet pack due to -NoPack" "Yellow"
} elseif ($DryRun) {
    Log ("Dry run: would produce package {0} version {1} containing {2} template(s)." -f $PackageId, $aggregatedVersion, $selectedTemplateCount) "DarkGray"
} else {
    $stagingSafe = Get-SafeName -Name $PackageId -Fallback "TemplatePack"
    $packStagingRoot = Join-Path $PackagesFullPath ("_staging_{0}" -f $stagingSafe)
    if (Test-Path $packStagingRoot) {
        Remove-Item -Path $packStagingRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $packStagingRoot | Out-Null

    $contentRoot = Join-Path $packStagingRoot "content"
    New-Item -ItemType Directory -Force -Path $contentRoot | Out-Null

    foreach ($summary in $sortedTemplateSummaries) {
        $sourceRoot = $summary.TemplateRoot
        if (-not (Test-Path $sourceRoot)) { continue }

        $destinationRoot = Join-Path $contentRoot $summary.FolderSafeName
        if (Test-Path $destinationRoot) {
            Remove-Item -Path $destinationRoot -Recurse -Force
        }
        New-Item -ItemType Directory -Force -Path $destinationRoot | Out-Null

        Get-ChildItem -LiteralPath $sourceRoot -Force | ForEach-Object {
            $destination = Join-Path $destinationRoot $_.Name
            Copy-Item -LiteralPath $_.FullName -Destination $destination -Recurse -Force
        }
    }

    $defaultTitle = if ($PackageTitle) {
        $PackageTitle
    } elseif ($aggregateAuthorsList.Count -eq 1) {
        "{0} Project Templates" -f $aggregateAuthorsList[0]
    } else {
        "Project Templates"
    }

    $title = if ($PackageTitle) { $PackageTitle } else { $defaultTitle }
    $description = if ($PackageDescription) { $PackageDescription } else {
        if ($templateNames.Count -gt 0) {
            "Includes templates: {0}" -f ($templateNames -join ", ")
        } else {
            "Collection of project templates."
        }
    }

    $projectBaseName = ($stagingSafe -replace "[^A-Za-z0-9]", '')
    if ([string]::IsNullOrWhiteSpace($projectBaseName)) {
        $projectBaseName = "TemplatePack"
    }
    $templateProjectPath = Join-Path $packStagingRoot ("{0}.TemplatePack.csproj" -f $projectBaseName)
    $templateProjectContent = @"
<Project Sdk='Microsoft.NET.Sdk'>
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <PackageId>$PackageId</PackageId>
    <Version>$aggregatedVersion</Version>
    <PackageType>Template</PackageType>
    <Authors>$([string]::Join(';', $aggregateAuthorsList))</Authors>
    <Title>$title</Title>
    <Description>$description</Description>
    <PackageTags>$aggregateTagsString</PackageTags>
    <IncludeBuildOutput>false</IncludeBuildOutput>
    <NoDefaultExcludes>true</NoDefaultExcludes>
    <EnableDefaultItems>false</EnableDefaultItems>
  </PropertyGroup>
  <ItemGroup>
    <None Include='content\**\*' Pack='true' PackagePath='content/' />
  </ItemGroup>
</Project>
"@
    Set-Content -Path $templateProjectPath -Value $templateProjectContent -Encoding UTF8

    Log ("🚀 Packing {0} template(s) into {1} v{2}..." -f $selectedTemplateCount, $PackageId, $aggregatedVersion) "Green"

    Log "  Restoring template pack project..." "DarkGray"
    $restoreArgs = @("restore", $templateProjectPath)
    & dotnet @restoreArgs | ForEach-Object { Log "    $_" "DarkGray" }
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet restore failed for aggregated package."
    }

    Log "  Packing template bundle..." "Green"
    $packArgs = @("pack", $templateProjectPath, "--no-build", "-c", "Release", "-o", $PackagesFullPath)
    & dotnet @packArgs | ForEach-Object { Log "    $_" "DarkGray" }
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet pack failed for aggregated package."
    }

    $expectedPackage = Join-Path $PackagesFullPath ("{0}.{1}.nupkg" -f $PackageId, $aggregatedVersion)
    if (Test-Path $expectedPackage) {
        Log "  Package created: $expectedPackage" "Green"
    } else {
        Log "  dotnet pack completed but package not found at expected path." "Yellow"
    }

    if (Test-Path $packStagingRoot) {
        Remove-Item -Path $packStagingRoot -Recurse -Force
    }

    if ($InstallLatestPackage -and $PackagesFullPath) {
        $latestInfo = Get-LatestPackageInfo -PackagesRoot $PackagesFullPath -Identity $PackageId
        if ($latestInfo) {
            $relativePackagePath = Get-RelativePath $RootPath $latestInfo.File.FullName
            $packageDisplayPath = $relativePackagePath ?? $latestInfo.File.FullName
            Log ("Uninstalling package if present: {0}" -f $PackageId)
            $uninstallArgs = @("new", "uninstall", $PackageId)
            & dotnet @uninstallArgs | ForEach-Object { Log ("    {0}" -f $_) "White" }
            $uninstallExitCode = $LASTEXITCODE
            if ($uninstallExitCode -eq 0) {
                Log "  Previous package removed." "Yellow"
            } elseif ($uninstallExitCode -eq 103) {
                Log "  Package not previously installed; skipping uninstall." "Green"
            } else {
                throw ("dotnet new uninstall failed for {0} (exit code {1})." -f $PackageId, $uninstallExitCode)
            }
            Log ("📦 Installing package: {0}" -f $packageDisplayPath)
            $installArgs = @("new", "install", "--force", $latestInfo.File.FullName)
            & dotnet @installArgs | ForEach-Object { Log ("    {0}" -f $_) "White" }
            if ($LASTEXITCODE -ne 0) {
                throw "dotnet new install failed for aggregated package."
            }
            Log "  Package installed." "Green"
        }
    }
}

# Persist aggregate config (version + per-template hashes)
try {
    $aggregateConfig.packageId = $PackageId
    $aggregateConfig.version = $aggregatedVersion
    if (-not $aggregateConfig.templates) { $aggregateConfig.templates = @{} }
    foreach ($summary in $sortedTemplateSummaries) {
        $id = $summary.Identity
        if ($id -and $currentHashes.ContainsKey($id)) {
            $aggregateConfig.templates[$id] = @{ hash = $currentHashes[$id] }
        }
    }
    if (-not $DryRun) {
        $cfgDir = Split-Path -Parent $aggregateConfigFullPath
        if ($cfgDir -and -not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null }
        ($aggregateConfig | ConvertTo-Json -Depth 10) | Set-Content -Path $aggregateConfigFullPath -Encoding UTF8
        Log ("Saved aggregate config: {0}" -f $aggregateConfigFullPath) "DarkGray"
    } else {
        Log ("Dry run: would save aggregate config to {0}" -f $aggregateConfigFullPath) "DarkGray"
    }
} catch {
    Log ("Failed to persist aggregate config: {0}" -f $_.Exception.Message) "Yellow"
}

Log "Export complete." "White"
