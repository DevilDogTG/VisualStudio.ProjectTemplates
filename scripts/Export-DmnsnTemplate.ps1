param (
    [string]$RootPath = (Resolve-Path "..\").Path,
    [switch]$DryRun,
    [string]$LogPath = "logs\exporting-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log"
)

# Enable error handling
$ErrorActionPreference = "Stop"

# ------------------------ LOGGING ------------------------
function Log {
    param ([string]$msg)
    Write-Host $msg
    if ($LogPath) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LogPath -Value ("[{0}] {1}" -f $timestamp, $msg)
    }
}

# Global trap for unexpected exceptions
trap {
    $err = $_.Exception.Message
    Write-Host "❌ ERROR: $err" -ForegroundColor Red
    Log $err
    exit 1
}

$srcPath = Join-Path $RootPath "src"
$outputPath = Join-Path $RootPath "output"
$logoPath = Join-Path $RootPath "logo.png"
$previewPath = Join-Path $RootPath "preview.png"

if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

# ------------------------ XML BUILDER ------------------------
function Generate-ProjectXml {
    param (
        [string]$basePath,
        [string]$folder,
        [array]$allowedFiles
    )

    $content = ""
    $currentPath = Join-Path $basePath $folder
    $entries = Get-ChildItem -Path $currentPath | Where-Object {
        $_.PSIsContainer -or $allowedFiles.FullName -contains $_.FullName
    }

    foreach ($entry in $entries) {
        $relPath = (Join-Path -Path "$folder" -ChildPath "$($entry.Name)") -replace '\\', '/'

        if ($entry.PSIsContainer) {
            $content += "      <Folder Name=""$($entry.Name)"" TargetFolderName=""$($entry.Name)"">`r`n"
            $content += Generate-ProjectXml -basePath $basePath -folder $relPath -allowedFiles $allowedFiles
            $content += "      </Folder>`r`n"
        }
        else {
            $content += "        <ProjectItem ReplaceParameters=""true"" TargetFileName=""$($entry.Name)"">$relPath</ProjectItem>`r`n"
        }
    }

    return $content
}

# ------------------------ TEMPLATE PROCESS ------------------------
$projectFolders = Get-ChildItem $srcPath -Directory
$tempWorkRoot = Join-Path $env:TEMP ('VSExport_' + [guid]::NewGuid())

foreach ($project in $projectFolders) {
    $projectPath = $project.FullName
    $configPath = Join-Path $projectPath "template.config.json"
    if (-not (Test-Path $configPath)) {
        Log "⚠ Skipping '$($project.Name)' (no config file)"
        continue
    } else {
        # --- BEGIN TEMP WORKDIR PATCH ---
        New-Item -ItemType Directory -Path $tempWorkRoot -Force | Out-Null
        $tempProjectPath = Join-Path $tempWorkRoot $project.Name
        Copy-Item -Path $projectPath -Destination $tempProjectPath -Recurse -Force
        $projectPath = $tempProjectPath
    }

    $config = Get-Content $configPath | ConvertFrom-Json
    $templateName = $config.name
    $description = $config.description
    $global:oldNamespace = $config.defaultNamespace
    $csproj = Get-ChildItem $projectPath -Filter *.csproj | Select-Object -First 1
    if (-not $csproj) {
        Log "⚠ Skipping '$($project.Name)' (no .csproj found)"
        continue
    }

    $zipName = "$($project.Name).zip"
    $zipPath = Join-Path $outputPath $zipName
    $vstemplatePath = Join-Path $projectPath "MyTemplate.vstemplate"

    Log "⚙ Processing '$($project.Name)'..."
    if ($DryRun) { Log "🔍 [DryRun] No changes will be made." }

    # Filter included files
    $excludedDirs = @("bin", "obj")
    $excludedFiles = @(
        ".zip", ".vstemplate", ".user", ".suo"
    )

    $entries = Get-ChildItem -Path $currentPath | Where-Object {
        $_.PSIsContainer -or $allowedFiles.FullName -contains $_.FullName
    }

    $filesToInclude = Get-ChildItem -Path $projectPath -Recurse -File | Where-Object {
        $isInExcludedDir = ($_.FullName -split '[\\/]' | Where-Object { $excludedDirs -contains $_ }).Count -gt 0
        $isExcludedExt = $excludedFiles -contains $_.Extension.ToLower()
        $isExcludedName = ($_.Name -ieq "template.config.json")
        -not ($isInExcludedDir -or $isExcludedExt -or $isExcludedName)
    }

    # 🔁 Replace namespace only in allowed files
    $filesToInclude | Where-Object {
        $_.Extension -in ".cs", ".csproj", ".json"
    } | ForEach-Object {
        $rel = $_.FullName.Substring($projectPath.Length + 1) -replace '\\', '/'
        Log "Replacing namespace in: ./$rel"
        if (-not $DryRun) {
            (Get-Content $_.FullName -Raw) -replace [regex]::Escape($global:oldNamespace), 'DMNSN.ConsoleApps' |
                Set-Content -Encoding UTF8 $_.FullName
        }
    }


    $excluded = Get-ChildItem -Path $projectPath -Recurse -File | Where-Object {
    -not ($filesToInclude.FullName -contains $_.FullName)
    }
    $excluded | ForEach-Object {
        Log "🚫 Excluded: $($_.FullName)"
    }


    # Build vstemplate
    $vstemplate = @"
<VSTemplate Version="3.0.0" xmlns="http://schemas.microsoft.com/developer/vstemplate/2005" Type="Project">
  <TemplateData>
    <Name>$templateName</Name>
    <Description>$description</Description>
    <ProjectType>CSharp</ProjectType>
    <SortOrder>1000</SortOrder>
    <CreateNewFolder>true</CreateNewFolder>
    <DefaultName>$global:oldNamespace</DefaultName>
    <ProvideDefaultName>true</ProvideDefaultName>
    <LocationField>Enabled</LocationField>
    <EnableLocationBrowseButton>true</EnableLocationBrowseButton>
    <CreateInPlace>true</CreateInPlace>
    <Icon>__TemplateIcon.png</Icon>
    <PreviewImage>__TemplatePreview.png</PreviewImage>
    <Category>DMNSN Templates</Category>
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
        Set-Content -Path $vstemplatePath -Value $vstemplate -Encoding UTF8
    }

    # Copy icon/preview
    if (Test-Path $logoPath) {
        Log "🖼️ Adding logo.png"
        if (-not $DryRun) {
            Copy-Item $logoPath -Destination (Join-Path $projectPath "__TemplateIcon.png") -Force
        }
    }
    if (Test-Path $previewPath) {
        Log "🖼️ Adding preview.png"
        if (-not $DryRun) {
            Copy-Item $previewPath -Destination (Join-Path $projectPath "__TemplatePreview.png") -Force
        }
    }

    # Create zip
    Log "📦 Packing to ZIP"
    if (-not $DryRun) {
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
            $destDir = Split-Path $dest
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item -Path $file.FullName -Destination $dest -Force
        }

        # Also copy vstemplate and icons into staging
        if (-not $DryRun) {
            Copy-Item -Path $vstemplatePath -Destination (Join-Path $tempZipDir "MyTemplate.vstemplate") -Force
            Copy-Item -Path (Join-Path $projectPath "__TemplateIcon.png") -Destination (Join-Path $tempZipDir "__TemplateIcon.png") -Force -ErrorAction SilentlyContinue
            Copy-Item -Path (Join-Path $projectPath "__TemplatePreview.png") -Destination (Join-Path $tempZipDir "__TemplatePreview.png") -Force -ErrorAction SilentlyContinue
        }

        # Zip from temp build folder
        Log "📦 Packing selected files to ZIP"
        if (-not $DryRun) {
            if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
            Compress-Archive -Path "$tempZipDir\*" -DestinationPath $zipPath -Force
            Remove-Item $tempZipDir -Recurse -Force
        }
    }

    # Clean up temp files
    if (-not $DryRun) {
        Remove-Item -Path (Join-Path $projectPath "__TemplateIcon.png") -Force -ErrorAction SilentlyContinue
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