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
        # %vsspv_user_appdata% should resolve to the user's profile directory
        # This is a Visual Studio specific variable that points to the user's home directory
        $userProfilePath = $env:USERPROFILE
        
        Write-Host "Resolving %vsspv_user_appdata% to user profile: $userProfilePath"
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

    Write-Host "Scanning for ProjectTemplatesLocation setting..."

    $settingsFiles = Get-ChildItem -Path $basePath -Recurse -Filter "CurrentSettings.vssettings" -ErrorAction SilentlyContinue

    foreach ($file in $settingsFiles) {
        Write-Host "Checking settings file: $($file.FullName)"
        try {
            [xml]$xml = Get-Content $file.FullName
            $nodes = $xml.SelectNodes("//PropertyValue[@name='ProjectTemplatesLocation']")
            Write-Host "Found $($nodes.Count) nodes for ProjectTemplatesLocation"
            foreach ($node in $nodes) {
                Write-Host "Node found: $($node.OuterXml)"
                $rawValue = $node.'#text'
                Write-Host "Raw value: $rawValue"
                if (-not $rawValue) {
                    $valueNode = $node.SelectSingleNode("Value")
                    if ($valueNode) {
                        $rawValue = $valueNode.InnerText
                    }
                }

                if ($rawValue) {
                    $expandedValue = Expand-VSEnvironmentVariable -Path $rawValue
                    Write-Host "Expanded value: $expandedValue"
                    
                    if (Test-Path $expandedValue) {
                        Write-Host "Found custom template path: $expandedValue"
                        return $expandedValue
                    } else {
                        Write-Host "Path does not exist: $expandedValue"
                    }
                }
            }
        } catch {
            Write-Host "Error reading $($file.FullName): $_"
        }
    }

    Write-Host "No custom setting found. Using default: $defaultPath"
    return $defaultPath
}

$vsTemplateBase = Get-VSProjectTemplatePath
Write-Host "Visual Studio Project Templates Path: $vsTemplateBase"
$vsTemplateTarget = Join-Path $vsTemplateBase $TargetFolderName

if (-not $DryRun -and -not (Test-Path $vsTemplateTarget)) {
    New-Item -ItemType Directory -Path $vsTemplateTarget -Force | Out-Null
}

$templateZips = Get-ChildItem -Path $SourcePath -Filter *.zip

if ($templateZips.Count -eq 0) {
    Write-Host "No templates found in: $SourcePath"
    exit 0
}

Write-Host "Found $($templateZips.Count) template(s) to import from: $SourcePath"
Write-Host "Target path: $vsTemplateTarget"

foreach ($zip in $templateZips) {
    $destPath = Join-Path $vsTemplateTarget $zip.Name

    if ($DryRun) {
        Write-Host "[DryRun] Would copy: $($zip.FullName) -> $destPath"
    } else {
        Copy-Item -Path $zip.FullName -Destination $destPath -Force
        Write-Host "Imported: $($zip.Name) -> $TargetFolderName"
    }
}

Write-Host ""
Write-Host "Templates available under: $vsTemplateTarget"
Write-Host "Launch Visual Studio -> File -> New -> Project -> Search your template"
