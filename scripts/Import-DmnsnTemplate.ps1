param (
    [string]$TargetFolderName = "DMNSN",
    [switch]$DryRun,
    [string]$LogPath
)

$ErrorActionPreference = "Stop"
$RootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent)
$SourcePath = Join-Path $RootPath "output"

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
    $LogPath = Join-Path $RootPath ("logs\importing-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
}

function Expand-VSEnvironmentVariable {
    param([string]$Path)
    
    if (-not $Path) { 
        return $Path 
    }
    
    if ($Path.Contains('%vsspv_user_appdata%')) {
        $userProfilePath = $env:USERPROFILE
        
        Log "🔄️ Resolving %vsspv_user_appdata% to user profile: $userProfilePath"
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

    Log "🔍 Scanning for ProjectTemplatesLocation setting..."

    $settingsFiles = Get-ChildItem -Path $basePath -Recurse -Filter "CurrentSettings.vssettings" -ErrorAction SilentlyContinue

    foreach ($file in $settingsFiles) {
        Log "📄 Checking settings file: $($file.FullName)"
        try {
            [xml]$xml = Get-Content $file.FullName
            $nodes = $xml.SelectNodes("//PropertyValue[@name='ProjectTemplatesLocation']")
            Log "👌 Found $($nodes.Count) nodes for ProjectTemplatesLocation"
            foreach ($node in $nodes) {
                Log "📍 Node found: $($node.OuterXml)"
                $rawValue = $node.'#text'
                Log "🔢 Raw value: $rawValue"
                if (-not $rawValue) {
                    $valueNode = $node.SelectSingleNode("Value")
                    if ($valueNode) {
                        $rawValue = $valueNode.InnerText
                    }
                }

                if ($rawValue) {
                    $expandedValue = Expand-VSEnvironmentVariable -Path $rawValue
                    Log "💥 Expanded value: $expandedValue"
                    
                    if (Test-Path $expandedValue) {
                        Log "✅ Found custom template path: $expandedValue"
                        return $expandedValue
                    } else {
                        Log "⚠️ Path does not exist: $expandedValue"
                    }
                }
            }
        } catch {
            Log "❌ Error reading $($file.FullName): $_"
        }
    }

    Log "⚠️ No custom setting found. Using default: $defaultPath"
    return $defaultPath
}

$vsTemplateBase = Get-VSProjectTemplatePath
Log "📂 Visual Studio Project Templates Path: $vsTemplateBase"
$vsTemplateTarget = Join-Path $vsTemplateBase $TargetFolderName

if (-not $DryRun -and -not (Test-Path $vsTemplateTarget)) {
    New-Item -ItemType Directory -Path $vsTemplateTarget -Force | Out-Null
}

$templateZips = Get-ChildItem -Path $SourcePath -Filter *.zip

if ($templateZips.Count -eq 0) {
    Log "⚠️ No templates found in: $SourcePath"
    exit 0
}

Log "👌 Found $($templateZips.Count) template(s) to import from: $SourcePath"
Log "📂 Target path: $vsTemplateTarget"

$importedAny = $false
foreach ($zip in $templateZips) {
    # --- REMOVE OLD VERSIONS IN DESTINATION ---
    $baseName = $zip.Name -replace '-v[\d\.]+\.zip$', ''
    $oldDestZips = Get-ChildItem -Path $vsTemplateTarget -Filter ("$baseName-v*.zip") -ErrorAction SilentlyContinue
    foreach ($oldDest in $oldDestZips) {
        if ($oldDest.Name -ne $zip.Name) {
            Log "🗑️ Removing old version from destination: $($oldDest.Name)"
            if (-not $DryRun) {
                Remove-Item $oldDest.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }

    $destPath = Join-Path $vsTemplateTarget $zip.Name

    if (Test-Path $destPath) {
        Log "⏩ Skipping import (already up-to-date): $($zip.Name)"
        continue
    }

    if ($DryRun) {
        Log "☑️ Would copy: $($zip.FullName) -> $destPath"
    } else {
        Copy-Item -Path $zip.FullName -Destination $destPath -Force
        Log "✅ Imported: $($zip.Name) -> $TargetFolderName"
        $importedAny = $true
    }
}

if ($importedAny) {
    Log "Finding `devenv` in PATH..."
    $devenvPath = Get-Command devenv -ErrorAction SilentlyContinue
    if (-not $devenvPath) {
        Log "❌ devenv not found in PATH. using default path."
        $vsInstallPath = Join-Path $env:ProgramFiles "Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe"
        if (Test-Path $vsInstallPath) {
            $devenvPath = $vsInstallPath
        } else {
            Log "❌ devenv not found at default path: $vsInstallPath"
            exit 1
        }
    } else {
        Log "✅ Found devenv at: $devenvPath"
    }
    Log "🔄️ Refreshing Visual Studio templates..."
    if ($DryRun) {
        Log "☑️ Would run: devenv /installvstemplates"
    } else {
        try {
            Log "Clearing old cache..."
            $cachePath = Join-Path $env:LOCALAPPDATA "Microsoft\VisualStudio\17.0\ComponentModelCache"
            if (Test-Path $cachePath) {
                Remove-Item -Path $cachePath -Recurse -Force
            }
            Log "✅ Cache cleared."
            Log "Running: $devenvPath /installvstemplates"
            & $devenvPath /installvstemplates | Out-Null
            Log "✅ Visual Studio templates refreshed successfully."
        } catch {
            Log "❌ Failed to refresh Visual Studio templates: $_"
        }
    }
} else {
    Log "⏩ No new templates imported. Skipping devenv refresh."
}

Log ""
Log "ℹ️  Templates available under: $vsTemplateTarget"
Log "ℹ️  Launch Visual Studio -> File -> New -> Project -> Search your template"
