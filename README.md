# Visual Studio Project Templates

Modern .NET project templates featuring Serilog logging, dependency injection, configuration, and opinionated defaults for jump-starting production-ready solutions.

> Maintained individually—responses to questions and issues may take time, but feedback is always welcome in the [Discussions](https://github.com/DevilDogTG/VisualStudio.ProjectTemplates/discussions) tab.

## Included templates

- DMNSN Console Application – Top-level program with structured logging, configuration, and DI support.
- DMNSN Web API – Minimal API bootstrap with Serilog enrichment and database-first EF Core wiring.
- DMNSN Worker Service – Background service/Windows Service scaffold with health checks and logging.
- DMNSN Class Library – Opinionated .NET class library with nullable enabled and packaging metadata.

All templates target .NET 8.0 and embrace a database-first pattern backed by SQL Server where applicable.

## Key features

- Serilog-based logging pipeline with sensible enrichers.
- Built-in dependency injection and configuration binding patterns.
- Database-first Entity Framework Core setup with bulk extension support (for Web API/Worker).
- Consistent code style and project structure across all templates.
- Automated export tooling that keeps metadata and packaging in sync.

## Dependencies

- Serilog
	- Serilog.Enrichers.AspNetCore.RequestHeader
	- Serilog.Enrichers.Environment
- Entity Framework Core
- EFCore.BulkExtensions
- Newtonsoft.Json

## Quick start

1. Export the templates by using:
	```powershell
	.\scripts\templates\Export-DotnetCliTemplate.ps1
	```
	- By default, all templates under `src` are exported.
	- Use `-Projects "ConsoleApp","Library"` to export specific templates.
	- Add `-DryRun` to preview changes or `-LogPath` to specify a custom log file.
2. Use the generated `.nupkg` files in `artifacts` to install or update the templates for `dotnet new`.
	```powershell
	dotnet new install .\artifacts\<template-name>.nupkg
	```
	- Replace the file name with any other package in `artifacts`.
	- Rerun `dotnet new install` with the newer `.nupkg` to update an existing installation.
3. Launch Visual Studio and create a new project using the DMNSN templates.

For project-specific coding conventions, see the `README.md` in each `src/DMNSN.Templates.Projects.*` folder.

### Uninstalling a template

```powershell
dotnet new uninstall DMNSN.ConsoleApp.CSharp
```

#### Finding the template identity

- `dotnet new list DMNSN` shows all installed DMNSN templates; the `Identity` column is the value for `dotnet new uninstall`.
- Each `src/DMNSN.Templates.Projects.*` folder contains a `template.config.json` with an `identity` property that matches the uninstall name.

## Export script usage (parameters and examples)

The export script lives at `scripts/templates/Export-DotnetCliTemplate.ps1` and builds `.nupkg` packages for `dotnet new install`.

- Export every template and create packages in `artifacts` (default):
  
  ```powershell
  .\scripts\templates\Export-DotnetCliTemplate.ps1
  ```

- Export specific templates (case-insensitive; partial names allowed):

  ```powershell
  .\scripts\templates\Export-DotnetCliTemplate.ps1 -Projects "ConsoleApp","WebApiRest"
  ```

- Set an explicit aggregate package version for the bundle:
  
  ```powershell
  .\scripts\templates\Export-DotnetCliTemplate.ps1 -Version 8.0.2
  ```

- Preview what would be produced without writing files or packing:

  ```powershell
  .\scripts\templates\Export-DotnetCliTemplate.ps1 -Projects "Library" -DryRun
  ```

- Skip building `.nupkg` files (useful when you only need the transformed template folder):

  ```powershell
  .\scripts\templates\Export-DotnetCliTemplate.ps1 -Projects "ConsoleApp" -NoPack
  ```

Additional switches:
- `-TemplatesPath` overrides the staging folder for generated templates (defaults to `output`).
- `-PackagesPath` controls where `.nupkg` files are written (defaults to `artifacts`).
- `-LogPath` writes the detailed log to a specific location; otherwise a timestamped file is placed under `logs`.
 - `-AggregateConfigPath` path to the running version config (defaults to `templatepack.config.json`).

Notes:
- Output templates are staged under `output` before packing. Older staged content for the same template is replaced each run.
- `.template.hash` files still track content changes in the source projects (skipped during `-DryRun`).
- The script maintains a running bundle version in `templatepack.config.json`; it bumps the patch version automatically if any selected template content changed since the last run. Use `-Version` to override explicitly.
- If `logo.ico` or `preview.png` exist at the repository root, they are bundled automatically as `__TemplateIcon.ico` and `__TemplatePreview.png`.

## Template configuration

Each template folder contains a `template.config.json` file. The export script reads this metadata and generates a rich `.vstemplate` manifest automatically.

Use this file as a quick pointer when browsing the repository structure:

1. Update the `template.config.json` of the template you want to export.
2. Consult the README for property descriptions, tag recommendations, and sample manifests.
3. Run `./scripts/templates/Export-DotnetCliTemplate.ps1 -Projects "ConsoleApp"` (swap in your project name) to regenerate the `.template.config` folder and pack a `.nupkg` for the dotnet CLI.

### Quick reference

```json
{
	"name": "Template Display Name",
	"description": "Detailed description of the template",
	"defaultNamespace": "YourProject.Namespace"
}
```

### Enhanced configuration

```json
{
	"name": "DMNSN Console Application",
	"description": "A modern console application template with logging, dependency injection, and configuration support",
	"defaultNamespace": "DMNSN.Templates.Projects.ConsoleApp",
	"author": "DMNSN",
	"version": "8.0.1",
	"tags": ["console", "application", "logging", "dependency-injection", "configuration"],
	"category": "Console Applications",
	"projectType": "CSharp",
	"languageTag": "csharp",
	"platformTag": "windows",
	"projectTypeTag": "console",
	"sortOrder": 1000,
	"createNewFolder": true,
	"provideDefaultName": true,
	"locationField": "Enabled",
	"enableLocationBrowseButton": true,
	"createInPlace": true,
	"requiredFrameworkVersion": "8.0",
	"supportedLanguages": ["C#"],
	"templateGroupIdentity": "DMNSN.Templates.Applications",
	"maxFrameworkVersion": "8.0"
}
```

### Required properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | string | Display name that appears in Visual Studio |
| `description` | string | What the template provides |
| `defaultNamespace` | string | Default namespace for generated projects |

### Optional properties

| Property | Type | Default | Description | Examples |
|----------|------|---------|-------------|----------|
| `author` | string | "Unknown" | Template author name | `"DMNSN"` |
| `version` | string | "1.0.0" | Semantic version used for packaging | `"8.0.1"` |
| `tags` | array | `[]` | Comma-separated metadata tags | `"console"`, `"logging"` |
| `category` | string | "General" | Custom grouping label | `"Console Applications"` |
| `projectType` | string | "CSharp" | Visual Studio root category | `"CSharp"`, `"Web"` |
| `languageTag` | string | "C#" | Language filter chip | `"csharp"` |
| `platformTag` | string | "Windows" | Platform filter chip | `"windows"`, `"azure"` |
| `projectTypeTag` | string | "project" | Template type filter | `"console"`, `"service"`, `"library"` |
| `sortOrder` | number | `1000` | Ordering inside category | `900` |
| `createNewFolder` | boolean | `true` | Creates a new folder when instantiating | `true`/`false` |
| `provideDefaultName` | boolean | `true` | Supplies a default project name | `true`/`false` |
| `locationField` | string | "Enabled" | Controls location textbox | `"Enabled"`, `"Hidden"` |
| `enableLocationBrowseButton` | boolean | `true` | Shows the browse button | `true`/`false` |
| `createInPlace` | boolean | `true` | Keeps project files in the selected folder | `true`/`false` |
| `requiredFrameworkVersion` | string | "4.0" | Minimum .NET version | `"8.0"` |
| `maxFrameworkVersion` | string | "" | Maximum .NET version | `"8.0"` |
| `templateGroupIdentity` | string | "" | Logical grouping across templates | `"DMNSN.Templates.Applications"` |
| `supportedLanguages` | array | `["C#"]` | Language list for template | `["C#"]`, `["C#","F#"]` |

### Built-in tag references

Project type (`projectType`)

- "CSharp", "VisualBasic", "Web", "VC"

Language tags (`languageTag`)

- "csharp", "visualbasic", "cpp", "fsharp", "javascript", "typescript", "python", "java", "querylanguage", "xaml"

Platform tags (`platformTag`)

- "windows", "android", "ios", "linux", "macos", "tvos", "xbox", "windowsappsdk", "azure"

Project type tags (`projectTypeTag`)

- "console", "desktop", "web", "mobile", "cloud", "service", "library", "test", "games", "iot", "extension", "office", "machinelearning", "uwp", "winui", "other"

### Recommended combinations

```json
// Console Application
{
	"projectType": "CSharp",
	"category": "Console Applications",
	"languageTag": "csharp",
	"platformTag": "windows",
	"projectTypeTag": "console"
}

// Web API
{
	"projectType": "CSharp",
	"category": "Web APIs",
	"languageTag": "csharp",
	"platformTag": "windows",
	"projectTypeTag": "web"
}

// Worker Service
{
	"projectType": "CSharp",
	"category": "Services",
	"languageTag": "csharp",
	"platformTag": "windows",
	"projectTypeTag": "service"
}

// Class Library
{
	"projectType": "CSharp",
	"category": "Class Libraries",
	"languageTag": "csharp",
	"platformTag": "any",
	"projectTypeTag": "classlib"
}
```

### How metadata maps to `.vstemplate`

| Config property | `<TemplateData>` element |
|-----------------|-------------------------|
| `name` | `<Name>` |
| `description` | `<Description>` |
| `projectType` | `<ProjectType>` |
| `sortOrder` | `<SortOrder>` |
| `createNewFolder` | `<CreateNewFolder>` |
| `defaultNamespace` | `<DefaultName>` |
| `provideDefaultName` | `<ProvideDefaultName>` |
| `locationField` | `<LocationField>` |
| `enableLocationBrowseButton` | `<EnableLocationBrowseButton>` |
| `createInPlace` | `<CreateInPlace>` |
| `author` | `<Author>` |
| `version` | `<Version>` |
| `tags` | `<ProjectSubType>` |
| `category` | `<ProjectCategory>` |
| `languageTag` | `<LanguageTag>` |
| `platformTag` | `<PlatformTag>` |
| `projectTypeTag` | `<ProjectTypeTag>` |
| `requiredFrameworkVersion` | `<RequiredFrameworkVersion>` |
| `maxFrameworkVersion` | `<MaxFrameworkVersion>` |
| `templateGroupIdentity` | `<TemplateGroupID>` |
| `supportedLanguages` | `<SupportedLanguages>` |

### Example generated manifest

```xml
<VSTemplate Version="3.0.0" xmlns="http://schemas.microsoft.com/developer/vstemplate/2005" Type="Project">
	<TemplateData>
		<Name>DMNSN Console Application</Name>
		<Description>A modern console application template with logging, dependency injection, and configuration support</Description>
		<ProjectType>CSharp</ProjectType>
		<SortOrder>1000</SortOrder>
		<CreateNewFolder>true</CreateNewFolder>
		<DefaultName>DMNSN.Templates.Projects.ConsoleApp</DefaultName>
		<ProvideDefaultName>true</ProvideDefaultName>
		<LocationField>Enabled</LocationField>
		<EnableLocationBrowseButton>true</EnableLocationBrowseButton>
		<CreateInPlace>true</CreateInPlace>
		<Icon>__TemplateIcon.ico</Icon>
		<PreviewImage>__TemplatePreview.png</PreviewImage>
		<Author>DMNSN</Author>
		<ProjectSubType>console,application,logging,dependency-injection,configuration</ProjectSubType>
		<ProjectCategory>Console Applications</ProjectCategory>
		<LanguageTag>csharp</LanguageTag>
		<PlatformTag>windows</PlatformTag>
		<ProjectTypeTag>console</ProjectTypeTag>
		<RequiredFrameworkVersion>8.0</RequiredFrameworkVersion>
		<MaxFrameworkVersion>8.0</MaxFrameworkVersion>
		<TemplateGroupID>DMNSN.Templates.Applications</TemplateGroupID>
		<SupportedLanguages>C#</SupportedLanguages>
	</TemplateData>
	<TemplateContent>
		<!-- Project files and structure -->
	</TemplateContent>
</VSTemplate>
```

### Export script diagnostics

Running the export script provides clear feedback about each template:

```
⚙ Processing 'DMNSN.Templates.Projects.ConsoleApp'...
📋 Template Name: DMNSN Console Application
👤 Author: DMNSN
🔢 Version: 8.0.1
🏷️ Tags: console,application,logging,dependency-injection,configuration
📂 Category: Console Applications
🎯 Project Type: CSharp
```

## Feedback and support

- File issues or feature requests in Discussions.
- Explore the sample code style in `src/DMNSN.Templates.Projects.ConsoleApp` and `src/DMNSN.Templates.Projects.Library`.
- Contributions and suggestions are welcome—help shape the next iteration of these templates.

