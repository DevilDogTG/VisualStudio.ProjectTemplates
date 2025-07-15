param (
    [string]$TargetFolderName = "DMNSN",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent)
$SourcePath = Join-Path $RootPath "output"

function Expand-VSEnvironmentVariable {
    param([string]$Path)
    
    if (-not $Path) { 
        return $Path 
    }
    
    if ($Path.Contains('%vsspv_user_appdata%')) {
        $userProfilePath = $env:USERPROFILE
        
        Write-Host "🔄️ Resolving %vsspv_user_appdata% to user profile: $userProfilePath" -ForegroundColor Blue
        $Path = $Path -replace '%vsspv_user_appdata%', $userProfilePath
    }
    
    $Path = $Path -replace '%USERPROFILE%', $env:USERPROFILE
    $Path = $Path -replace '%LOCALAPPDATA%', $env:LOCALAPPDATA
    $Path = $Path -replace '%APPDATA%', $env:APPDATA
    
    return $Path
}

function Get-VSProjectTemplatePath {
    $defaultPath = Join-Path $env:USERPROFILE "Documents\Visual Studio 2022\Templates\ProjectTemplates"
    $basePath = Join-Path $env:LOCALAPPDATA "Microsoft\VisualStudio"

    Write-Host "🔍 Scanning for ProjectTemplatesLocation setting..." -ForegroundColor Blue

    $settingsFiles = Get-ChildItem -Path $basePath -Recurse -Filter "CurrentSettings.vssettings" -ErrorAction SilentlyContinue

    foreach ($file in $settingsFiles) {
        Write-Host "📄 Checking settings file: $($file.FullName)" -ForegroundColor Gray
        try {
            [xml]$xml = Get-Content $file.FullName
            $nodes = $xml.SelectNodes("//PropertyValue[@name='ProjectTemplatesLocation']")
            Write-Host "👌 Found $($nodes.Count) nodes for ProjectTemplatesLocation" -ForegroundColor Blue
            foreach ($node in $nodes) {
                Write-Host "📍 Node found: $($node.OuterXml)" -ForegroundColor Gray
                $rawValue = $node.'#text'
                Write-Host "#️⃣  Raw value: $rawValue" -ForegroundColor Blue
                if (-not $rawValue) {
                    $valueNode = $node.SelectSingleNode("Value")
                    if ($valueNode) {
                        $rawValue = $valueNode.InnerText
                    }
                }

                if ($rawValue) {
                    $expandedValue = Expand-VSEnvironmentVariable -Path $rawValue
                    Write-Host "💥 Expanded value: $expandedValue" -ForegroundColor Blue
                    
                    if (Test-Path $expandedValue) {
                        Write-Host "✅ Found custom template path: $expandedValue" -ForegroundColor Green
                        return $expandedValue
                    } else {
                        Write-Host "⚠️ Path does not exist: $expandedValue" -ForegroundColor Yellow
                    }
                }
            }
        } catch {
            Write-Host "❌ Error reading $($file.FullName): $_" -ForegroundColor Red
        }
    }

    Write-Host "⚠️ No custom setting found. Using default: $defaultPath" -ForegroundColor Gray
    return $defaultPath
}

$vsTemplateBase = Get-VSProjectTemplatePath
Write-Host "📂 Visual Studio Project Templates Path: $vsTemplateBase" -ForegroundColor Cyan
$vsTemplateTarget = Join-Path $vsTemplateBase $TargetFolderName

if (-not $DryRun -and -not (Test-Path $vsTemplateTarget)) {
    New-Item -ItemType Directory -Path $vsTemplateTarget -Force | Out-Null
}

$templateZips = Get-ChildItem -Path $SourcePath -Filter *.zip

if ($templateZips.Count -eq 0) {
    Write-Host "⚠️ No templates found in: $SourcePath" -ForegroundColor Yellow
    exit 0
}

Write-Host "👌 Found $($templateZips.Count) template(s) to import from: $SourcePath" -ForegroundColor Cyan
Write-Host "📂 Target path: $vsTemplateTarget" -ForegroundColor Cyan

foreach ($zip in $templateZips) {
    $destPath = Join-Path $vsTemplateTarget $zip.Name

    if ($DryRun) {
        Write-Host "☑️ Would copy: $($zip.FullName) -> $destPath" -ForegroundColor Yellow
    } else {
        Copy-Item -Path $zip.FullName -Destination $destPath -Force
        Write-Host "✅ Imported: $($zip.Name) -> $TargetFolderName" -ForegroundColor Green
    }
}
Write-Host "Finding `devenv` in PATH..."
$devenvPath = Get-Command devenv -ErrorAction SilentlyContinue
if (-not $devenvPath) {
    Write-Host "❌ devenv not found in PATH. using default path." -ForegroundColor Red
    $vsInstallPath = Join-Path $env:ProgramFiles "Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe"
    if (Test-Path $vsInstallPath) {
        $devenvPath = $vsInstallPath
    } else {
        Write-Host "❌ devenv not found at default path: $vsInstallPath" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ Found devenv at: $devenvPath" -ForegroundColor Green
}
Write-Host "🔄️ Refreshing Visual Studio templates..."
if ($DryRun) {
    Write-Host "☑️ Would run: devenv /installvstemplates" -ForegroundColor Yellow
} else {
    try {
        Write-Host "Clearing old cache..."
        $cachePath = Join-Path $env:LOCALAPPDATA "Microsoft\VisualStudio\17.0\ComponentModelCache"
        if (Test-Path $cachePath) {
            Remove-Item -Path $cachePath -Recurse -Force
        }
        Write-Host "✅ Cache cleared." -ForegroundColor Green
        
        Write-Host "Running: $devenvPath /installvstemplates" -ForegroundColor Cyan
        & $devenvPath /installvstemplates | Out-Null
        Write-Host "✅ Visual Studio templates refreshed successfully." -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to refresh Visual Studio templates: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "ℹ️  Templates available under: $vsTemplateTarget" -ForegroundColor Green
Write-Host "ℹ️  Launch Visual Studio -> File -> New -> Project -> Search your template" -ForegroundColor Cyan
