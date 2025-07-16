param (
    [switch]$DryRun,
    [string]$LogPath
)

# ------------------------ LOGGING ------------------------
function Log {
    param ([string]$msg)
    Write-Host $msg
    if ($LogPath) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LogPath -Value ("[{0}] {1}" -f $timestamp, $msg)
    }
}

# Enable error handling
$ErrorActionPreference = "Stop"

# Set root path is 1 level up from the script path
$RootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent)

# Initialize LogPath if not provided
if (-not $LogPath) {
    $LogPath = Join-Path $RootPath ("logs\exporting-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
}

# Root path validation
if (-not (Test-Path $RootPath)) {
    Write-Host "❌ ERROR: Script path does not exist: $RootPath" -ForegroundColor Red
    exit 1
}

$srcPath = Join-Path $RootPath "src"
$outputPath = Join-Path $RootPath "output"
$logoPath = Join-Path $RootPath "logo.ico"
$previewPath = Join-Path $RootPath "preview.png"

# Ensure the log directory exists
$logDir = Split-Path -Path $LogPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType File -Path $LogPath -Force | Out-Null
}

# Global trap for unexpected exceptions
trap {
    $err = $_.Exception.Message
    Write-Host "❌ ERROR: $err" -ForegroundColor Red
    Log "❌ ERROR: $err"
    exit 1
}

# Create output directory if it doesn't exist
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

# ------------------------ XML BUILDER ------------------------
function Generate-ProjectXml {
    param (
        [string]$basePath,
        [string]$folder,
        [array]$allowedFiles,
        [int]$indentLevel = 0
    )

    $indent = '  ' * $indentLevel
    $content = ""
    $currentPath = Join-Path $basePath $folder

    # Filter entries (folders or allowed files only)
    $entries = Get-ChildItem -Path $currentPath -Force | Where-Object {
        if ($_.PSIsContainer) {
            $subtree = $allowedFiles | Where-Object { $_.FullName.StartsWith($_.FullName) }
            return $subtree.Count -gt 0
        } else {
            return $allowedFiles.FullName -contains $_.FullName
        }
    }

    foreach ($entry in $entries) {
        $relPath = (Join-Path -Path "$folder" -ChildPath "$($entry.Name)") -replace '\\', '/'

        if ($entry.PSIsContainer) {
            $childContent = Generate-ProjectXml -basePath $basePath -folder $relPath -allowedFiles $allowedFiles -indentLevel ($indentLevel + 1)
            if ($childContent.Trim()) {
                $content += "$indent  <Folder Name=""$($entry.Name)"" TargetFolderName=""$($entry.Name)"">`r`n"
                $content += $childContent
                $content += "$indent  </Folder>`r`n"
                Log "$indent📁 $relPath"
            }
        } else {
            $content += "$indent    <ProjectItem ReplaceParameters=""true"" TargetFileName=""$($entry.Name)"">$($entry.Name)</ProjectItem>`r`n"
            Log "$indent📄 $relPath"
        }
    }

    return $content
}
# ------------------------ TEMPLATE PROCESS ------------------------
$projectFolders = Get-ChildItem $srcPath -Directory -ErrorAction SilentlyContinue
if (-not $projectFolders) {
    Log "❌ ERROR: No project folders found in: $srcPath"
    exit 1
}

$tempWorkRoot = Join-Path $env:TEMP ('VSExport_' + [guid]::NewGuid())

foreach ($project in $projectFolders) {
    $projectPath = $project.FullName
    $configPath = Join-Path $projectPath "template.config.json"
    
    if (-not (Test-Path $configPath)) {
        Log "⚠ Skipping '$($project.Name)' (no config file)"
        continue
    }

    # --- BEGIN TEMP WORKDIR PATCH ---
    try {
        New-Item -ItemType Directory -Path $tempWorkRoot -Force | Out-Null
        $tempProjectPath = Join-Path $tempWorkRoot $project.Name
        Copy-Item -Path $projectPath -Destination $tempProjectPath -Recurse -Force
        $projectPath = $tempProjectPath
    }
    catch {
        Log "❌ ERROR: Failed to create temp directory: $_"
        continue
    }

    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        $templateName = $config.name
        $description = $config.description
        $global:oldNamespace = $config.defaultNamespace
        
        # Enhanced configuration properties with defaults
        $author = if ($config.author) { $config.author } else { "Unknown" }
        $version = if ($config.version) { $config.version } else { "1.0.0" }
        $tags = if ($config.tags) { $config.tags -join "," } else { "" }
        $category = if ($config.category) { $config.category } else { "General" }
        $projectType = if ($config.projectType) { $config.projectType } else { "CSharp" }
        $languageTag = if ($config.languageTag) { $config.languageTag } else { "C#" }
        $platformTag = if ($config.platformTag) { $config.platformTag } else { "Windows" }
        $projectTypeTag = if ($config.projectTypeTag) { $config.projectTypeTag } else { "project" }
        $sortOrder = if ($config.sortOrder) { $config.sortOrder } else { 1000 }
        $createNewFolder = if ($config.createNewFolder -ne $null) { $config.createNewFolder.ToString().ToLower() } else { "true" }
        $provideDefaultName = if ($config.provideDefaultName -ne $null) { $config.provideDefaultName.ToString().ToLower() } else { "true" }
        $locationField = if ($config.locationField) { $config.locationField } else { "Enabled" }
        $enableLocationBrowseButton = if ($config.enableLocationBrowseButton -ne $null) { $config.enableLocationBrowseButton.ToString().ToLower() } else { "true" }
        $createInPlace = if ($config.createInPlace -ne $null) { $config.createInPlace.ToString().ToLower() } else { "true" }
        $requiredFrameworkVersion = if ($config.requiredFrameworkVersion) { $config.requiredFrameworkVersion } else { "4.0" }
        $maxFrameworkVersion = if ($config.maxFrameworkVersion) { $config.maxFrameworkVersion } else { "" }
        $templateGroupIdentity = if ($config.templateGroupIdentity) { $config.templateGroupIdentity } else { "" }
        $supportedLanguages = if ($config.supportedLanguages) { $config.supportedLanguages -join "," } else { "C#" }
    }
    catch {
        Log "❌ ERROR: Failed to parse config file: $_"
        continue
    }

    $csproj = Get-ChildItem $projectPath -Filter *.csproj -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $csproj) {
        Log "⚠ Skipping '$($project.Name)' (no .csproj found)"
        continue
    }

    # --- VERSIONED ZIP NAME ---
    $zipName = "{0}-v{1}.zip" -f $project.Name, $version
    $zipPath = Join-Path $outputPath $zipName
    $vstemplatePath = Join-Path $projectPath "MyTemplate.vstemplate"

    # --- REMOVE OLD VERSIONS ---
    $oldZips = Get-ChildItem -Path $outputPath -Filter ("{0}-v*.zip" -f $project.Name) -ErrorAction SilentlyContinue
    foreach ($oldZip in $oldZips) {
        if ($oldZip.FullName -ne $zipPath) {
            Log "🗑️ Removing old version: $($oldZip.Name)"
            if (-not $DryRun) {
                Remove-Item $oldZip.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Log "⚙ Processing '$($project.Name)'..."
    Log "📋 Template Name: $templateName"
    Log "👤 Author: $author"
    Log "🔢 Version: $version"
    Log "🏷️ Tags: $tags"
    Log "📂 Category: $category"
    Log "🎯 Project Type: $projectType"
    if ($DryRun) { Log "🔍 [DryRun] No changes will be made." }

    # Filter included files
    $excludedDirs = @("bin", "obj", "logs", ".vs", ".git")
    $excludedFiles = @(".zip", ".vstemplate", ".user", ".suo", ".gitignore", ".gitattributes")
    $excludedNames = @("template.config.json")

    $filesToInclude = Get-ChildItem -Path $projectPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $relativePath = $_.FullName.Substring($projectPath.Length + 1)
        $pathParts = $relativePath -split '[\\/]'
        $isInExcludedDir = ($pathParts | Where-Object { $excludedDirs -contains $_ }).Count -gt 0
        $isExcludedExt = $excludedFiles -contains $_.Extension.ToLower()
        $isExcludedName = $excludedNames -contains $_.Name
        -not ($isInExcludedDir -or $isExcludedExt -or $isExcludedName)
    }

    # 🔁 Replace namespace only in allowed files
    $filesToInclude | Where-Object {
        $_.Extension -in @(".cs", ".csproj", ".json")
    } | ForEach-Object {
        $rel = $_.FullName.Substring($projectPath.Length + 1) -replace '\\', '/'
        Log "Replacing namespace in: ./$rel"
        if (-not $DryRun) {
            try {
                $content = Get-Content $_.FullName -Raw -ErrorAction Stop
                $newContent = $content -replace [regex]::Escape($global:oldNamespace), '$safeprojectname$'
                Set-Content -Path $_.FullName -Value $newContent -Encoding UTF8 -NoNewline
            }
            catch {
                Log "⚠ Warning: Failed to replace namespace in $($_.FullName): $_"
            }
        }
    }

    # Log excluded files
    $actualExcludedFiles = Get-ChildItem -Path $projectPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        -not ($filesToInclude.FullName -contains $_.FullName)
    }
    $actualExcludedFiles | ForEach-Object {
        $rel = $_.FullName.Substring($projectPath.Length + 1) -replace '\\', '/'
        Log "🚫 Excluded: ./$rel"
    }

    # Build vstemplate
    $vstemplate = @"
<VSTemplate Version="3.0.0" xmlns="http://schemas.microsoft.com/developer/vstemplate/2005" Type="Project">
  <TemplateData>
    <Name>$templateName</Name>
    <Description>$description</Description>
    <ProjectType>$projectType</ProjectType>
    <SortOrder>$sortOrder</SortOrder>
    <CreateNewFolder>$createNewFolder</CreateNewFolder>
    <DefaultName>$global:oldNamespace</DefaultName>
    <ProvideDefaultName>$provideDefaultName</ProvideDefaultName>
    <LocationField>$locationField</LocationField>
    <EnableLocationBrowseButton>$enableLocationBrowseButton</EnableLocationBrowseButton>
    <CreateInPlace>$createInPlace</CreateInPlace>
    <Icon>__TemplateIcon.ico</Icon>
    <PreviewImage>__TemplatePreview.png</PreviewImage>
"@

    # Add optional elements if they exist
    if ($author -ne "Unknown") {
        $vstemplate += "    <Author>$author</Author>`r`n"
    }
    if ($version -ne "1.0.0") {
        $vstemplate += "    <Version>$version</Version>`r`n"
    }
    if ($tags) {
        $vstemplate += "    <ProjectSubType>$tags</ProjectSubType>`r`n"
    }
    if ($category -ne "General") {
        $vstemplate += "    <ProjectCategory>$category</ProjectCategory>`r`n"
    }
    if ($languageTag) {
        $vstemplate += "    <LanguageTag>$languageTag</LanguageTag>`r`n"
    }
    if ($platformTag) {
        $vstemplate += "    <PlatformTag>$platformTag</PlatformTag>`r`n"
    }
    if ($projectTypeTag) {
        $vstemplate += "    <ProjectTypeTag>$projectTypeTag</ProjectTypeTag>`r`n"
    }
    if ($requiredFrameworkVersion) {
        $vstemplate += "    <RequiredFrameworkVersion>$requiredFrameworkVersion</RequiredFrameworkVersion>`r`n"
    }
    if ($maxFrameworkVersion) {
        $vstemplate += "    <MaxFrameworkVersion>$maxFrameworkVersion</MaxFrameworkVersion>`r`n"
    }
    if ($templateGroupIdentity) {
        $vstemplate += "    <TemplateGroupID>$templateGroupIdentity</TemplateGroupID>`r`n"
    }
    if ($supportedLanguages) {
        $vstemplate += "    <SupportedLanguages>$supportedLanguages</SupportedLanguages>`r`n"
    }

    $vstemplate += @"
  </TemplateData>
  <TemplateContent>
    <Project TargetFileName="$($csproj.Name)" File="$($csproj.Name)" ReplaceParameters="true">
"@

    $vstemplate += Generate-ProjectXml -basePath $projectPath -folder "." -allowedFiles $filesToInclude
    $vstemplate += @"
    </Project>
  </TemplateContent>
</VSTemplate>
"@

    Log "📄 Generating vstemplate"
    if (-not $DryRun) {
        try {
            Set-Content -Path $vstemplatePath -Value $vstemplate -Encoding UTF8
        }
        catch {
            Log "❌ ERROR: Failed to create vstemplate: $_"
            continue
        }
    }

    # Copy icon/preview
    if (Test-Path $logoPath) {
        Log "🖼️ Adding logo.ico"
        if (-not $DryRun) {
            try {
                Copy-Item $logoPath -Destination (Join-Path $projectPath "__TemplateIcon.ico") -Force
            }
            catch {
                Log "⚠ Warning: Failed to copy logo: $_"
            }
        }
    }
    if (Test-Path $previewPath) {
        Log "🖼️ Adding preview.png"
        if (-not $DryRun) {
            try {
                Copy-Item $previewPath -Destination (Join-Path $projectPath "__TemplatePreview.png") -Force
            }
            catch {
                Log "⚠ Warning: Failed to copy preview: $_"
            }
        }
    }

    # Create zip
    Log "📦 Packing to ZIP"
    if (-not $DryRun) {
        try {
            if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
            
            # Build relative paths for inclusion
            $tempZipDir = Join-Path $projectPath "_template_build"
            if (Test-Path $tempZipDir) {
                Remove-Item $tempZipDir -Recurse -Force
            }
            New-Item -ItemType Directory -Path $tempZipDir | Out-Null

            foreach ($file in $filesToInclude) {
                $relative = $file.FullName.Substring($projectPath.Length + 1)
                $dest = Join-Path $tempZipDir $relative
                $destDir = Split-Path $dest -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                Copy-Item -Path $file.FullName -Destination $dest -Force
            }

            # Also copy vstemplate and icons into staging
            Copy-Item -Path $vstemplatePath -Destination (Join-Path $tempZipDir "MyTemplate.vstemplate") -Force
            if (Test-Path (Join-Path $projectPath "__TemplateIcon.ico")) {
                Copy-Item -Path (Join-Path $projectPath "__TemplateIcon.ico") -Destination (Join-Path $tempZipDir "__TemplateIcon.ico") -Force
            }
            if (Test-Path (Join-Path $projectPath "__TemplatePreview.png")) {
                Copy-Item -Path (Join-Path $projectPath "__TemplatePreview.png") -Destination (Join-Path $tempZipDir "__TemplatePreview.png") -Force
            }

            # Zip from temp build folder
            Log "📦 Packing selected files to ZIP"
            Compress-Archive -Path "$tempZipDir\*" -DestinationPath $zipPath -Force
            Remove-Item $tempZipDir -Recurse -Force
        }
        catch {
            Log "❌ ERROR: Failed to create ZIP: $_"
            continue
        }
    }

    # Clean up temp files
    if (-not $DryRun) {
        Remove-Item -Path (Join-Path $projectPath "__TemplateIcon.ico") -Force -ErrorAction SilentlyContinue
        Remove-Item -Path (Join-Path $projectPath "__TemplatePreview.png") -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $vstemplatePath -Force -ErrorAction SilentlyContinue
    }

    Log "✅ Done: $zipPath`n"
}

# --- CLEANUP TEMP WORKDIR ---
if (Test-Path $tempWorkRoot) {
    Remove-Item -Path $tempWorkRoot -Recurse -Force -ErrorAction SilentlyContinue
}
Log "🎯 All templates saved in: $outputPath"