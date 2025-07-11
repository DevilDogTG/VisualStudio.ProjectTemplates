param (
    [string]$RootPath = (Resolve-Path "..\").Path,
    [switch]$DryRun,
    [string]$LogPath = ""
)

$srcPath = Join-Path $RootPath "src"
$outputPath = Join-Path $RootPath "output"
$logoPath = Join-Path $RootPath "logo.png"
$previewPath = Join-Path $RootPath "preview.png"

if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

# ------------------------ LOGGING ------------------------
function Log {
    param ([string]$msg)
    Write-Host $msg
    if ($LogPath) { Add-Content -Path $LogPath -Value "[{0}] {1}" -f (Get-Date), $msg }
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
        $relPath = Join-Path $folder $entry.Name -replace '\\', '/'

        if ($entry.PSIsContainer) {
            $content += "      <Folder Name=""$($entry.Name)"" TargetFolderName=""$($entry.Name)"">`r`n"
            $content += Generate-ProjectXml -basePath $basePath -folder $relPath -allowedFiles $allowedFiles
            $content += "      </Folder>`r`n"
        }
        else {
            if ($entry.Extension -in ".cs", ".csproj", ".json") {
                $msg = "Replacing namespace in: $relPath"
                Log $msg
                if (-not $DryRun) {
                    (Get-Content $entry.FullName -Raw) -replace [regex]::Escape($global:oldNamespace), '$safeprojectname$' |
                        Set-Content -Encoding UTF8 $entry.FullName
                }
            }
            $content += "        <ProjectItem ReplaceParameters=""true"" TargetFileName=""$($entry.Name)"">$relPath</ProjectItem>`r`n"
        }
    }

    return $content
}

# ------------------------ TEMPLATE PROCESS ------------------------
$projectFolders = Get-ChildItem $srcPath -Directory

foreach ($project in $projectFolders) {
    $projectPath = $project.FullName
    $configPath = Join-Path $projectPath "template.config.json"
    if (-not (Test-Path $configPath)) {
        Log "⚠ Skipping '$($project.Name)' (no config file)"
        continue
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
    $filesToInclude = Get-ChildItem -Path $projectPath -Recurse -File | Where-Object {
        $_.FullName -notmatch '\\bin\\|\\obj\\' -and
        $_.Extension -notin ".zip", ".vstemplate", ".user", ".suo"
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
        Compress-Archive -Path "$projectPath\*" -DestinationPath $zipPath -Force
    }

    # Clean up temp files
    if (-not $DryRun) {
        Remove-Item -Path (Join-Path $projectPath "__TemplateIcon.png") -Force -ErrorAction SilentlyContinue
        Remove-Item -Path (Join-Path $projectPath "__TemplatePreview.png") -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $vstemplatePath -Force -ErrorAction SilentlyContinue
    }

    Log "✅ Done: $zipPath`n"
}

Log "🎯 All templates saved in: $outputPath"
