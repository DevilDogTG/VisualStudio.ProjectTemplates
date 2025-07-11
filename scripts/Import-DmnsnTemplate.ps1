param (
    [string]$SourcePath = (Resolve-Path "..\output").Path,
    [string]$TargetFolderName = "DMNSN",  # Your desired subfolder under ProjectTemplates
    [switch]$DryRun
)

function Get-VSProjectTemplatePath {
    $defaultPath = Join-Path $env:USERPROFILE "Documents\Visual Studio 2022\Templates\ProjectTemplates"
    $basePath = Join-Path $env:LOCALAPPDATA "Microsoft\VisualStudio"

    Write-Host "🔍 Scanning for ProjectTemplatesLocation setting..."

    $settingsFiles = Get-ChildItem -Path $basePath -Recurse -Filter "CurrentSettings.vssettings" -ErrorAction SilentlyContinue

    foreach ($file in $settingsFiles) {
        try {
            [xml]$xml = Get-Content $file.FullName
            $nodes = $xml.SelectNodes("//PropertyValue[@name='ProjectTemplatesLocation']")
            foreach ($node in $nodes) {
                $rawValue = $node.'#text'  # handles direct inner text
                if (-not $rawValue) {
                    $valueNode = $node.SelectSingleNode("Value")
                    $rawValue = $valueNode.InnerText
                }

                if ($rawValue -and (Test-Path $rawValue)) {
                    Write-Host "✅ Found custom template path: $rawValue"
                    return $rawValue
                }
            }
        } catch {
            Write-Host "⚠ Error reading $($file.FullName): $_"
        }
    }

    Write-Host "📁 No custom setting found. Using default: $defaultPath"
    return $defaultPath
}

# Resolve target path
$vsTemplateBase = Get-VSProjectTemplatePath
Write-Host "📂 Visual Studio Project Templates Path: $vsTemplateBase"
$vsTemplateTarget = Join-Path $vsTemplateBase $TargetFolderName

# Create if missing
if (-not $DryRun -and -not (Test-Path $vsTemplateTarget)) {
    New-Item -ItemType Directory -Path $vsTemplateTarget -Force | Out-Null
}

# Get templates
$templateZips = Get-ChildItem -Path $SourcePath -Filter *.zip

if ($templateZips.Count -eq 0) {
    Write-Host "⚠ No templates found in: $SourcePath"
    exit 0
}

Write-Host "📦 Found $($templateZips.Count) template(s) to import from: $SourcePath"
Write-Host "📁 Target path: $vsTemplateTarget`n"

foreach ($zip in $templateZips) {
    $destPath = Join-Path $vsTemplateTarget $zip.Name

    if ($DryRun) {
        Write-Host "🔍 [DryRun] Would copy: $($zip.FullName) → $destPath"
    } else {
        Copy-Item -Path $zip.FullName -Destination $destPath -Force
        Write-Host "✅ Imported: $($zip.Name) → $TargetFolderName"
    }
}

Write-Host "`n🎯 Templates available under: $vsTemplateTarget"
Write-Host "🧭 Launch Visual Studio → File → New → Project → Search your template"
