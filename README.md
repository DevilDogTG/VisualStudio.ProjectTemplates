# Visual Studio Project Templates

Modern .NET project templates featuring Serilog logging, dependency injection, configuration, and opinionated defaults for jump-starting production-ready solutions.

> Maintained individually—responses to questions and issues may take time, but feedback is always welcome in the [Discussions](https://github.com/DevilDogTG/visualstudio-projects-template/discussions) tab.

## Included templates

- **DMNSN Console Application** – Top-level program with structured logging, configuration, and DI support.
- **DMNSN Web API** – Minimal API bootstrap with Serilog enrichment and database-first EF Core wiring.
- **DMNSN Worker Service** – Background service/Windows Service scaffold with health checks and logging.

All templates target **.NET 8.0** and embrace a database-first pattern backed by SQL Server.

## Key features

- Serilog-based logging pipeline with sensible enrichers.
- Built-in dependency injection and configuration binding patterns.
- Database-first Entity Framework Core setup with bulk extension support.
- Consistent code style and project structure across all templates.
- Automated export tooling that keeps metadata and packaging in sync.

## Dependencies

- [Serilog](https://serilog.net/)
	- [Serilog.Enrichers.AspNetCore.RequestHeader](https://github.com/DevilDogTG/serilog-enrichers-aspnetcore)
	- [Serilog.Enrichers.Environment](https://github.com/serilog/serilog-enrichers-environment)
- [Entity Framework Core](https://docs.microsoft.com/en-us/ef/core/)
- [EFCore.BulkExtensions](https://github.com/borisdj/EFCore.BulkExtensions)
- [Newtonsoft.Json](https://www.newtonsoft.com/json)

## Quick start

1. Export the templates to `./output`:
	 ```powershell
	 ./scripts/Export-DmnsnTemplate.ps1
	 ```
	 - Use `-DryRun` to preview changes or `-LogPath` to specify a custom log file.
2. Install the generated ZIP(s) into Visual Studio:
	 ```powershell
	 Copy-Item -Path .\output\* -Destination "$env:USERPROFILE\Documents\Visual Studio 2022\Templates\ProjectTemplates" -Recurse -Force
	 ```
	 Replace `Visual Studio 2022` with your installed version path if different.
3. Launch Visual Studio and create a new project using the DMNSN templates.

For project-specific coding conventions, see `src/DMNSN.Templates.Project.ConsoleApp/README.md`.

## Template configuration

Each template folder contains a `template.config.json` file. The export script reads this metadata and generates a rich `.vstemplate` manifest automatically.

### Quick reference

**Basic configuration**

```json
{
	"name": "Template Display Name",
	"description": "Detailed description of the template",
	"defaultNamespace": "YourProject.Namespace"
}
```

**Enhanced configuration**

```json
{
	"name": "DMNSN Console Application",
	"description": "A modern console application template with logging, dependency injection, and configuration support",
	"defaultNamespace": "DMNSN.Templates.Project.ConsoleApp",
	"author": "DMNSN",
	"version": "8.0.17",
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
| `version` | string | "1.0.0" | Semantic version used for packaging | `"8.0.17"` |
| `tags` | array | `[]` | Comma-separated metadata tags | `"console"`, `"logging"` |
| `category` | string | "General" | Custom grouping label | `"Console Applications"` |
| `projectType` | string | "CSharp" | Visual Studio root category | `"CSharp"`, `"Web"` |
| `languageTag` | string | "C#" | Language filter chip | `"csharp"` |
| `platformTag` | string | "Windows" | Platform filter chip | `"windows"`, `"azure"` |
| `projectTypeTag` | string | "project" | Template type filter | `"console"`, `"service"` |
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

**Project type (`projectType`)**

- `"CSharp"`, `"VisualBasic"`, `"Web"`, `"VC"`

**Language tags (`languageTag`)**

- `"csharp"`, `"visualbasic"`, `"cpp"`, `"fsharp"`, `"javascript"`, `"typescript"`, `"python"`, `"java"`, `"querylanguage"`, `"xaml"`

**Platform tags (`platformTag`)**

- `"windows"`, `"android"`, `"ios"`, `"linux"`, `"macos"`, `"tvos"`, `"xbox"`, `"windowsappsdk"`, `"azure"`

**Project type tags (`projectTypeTag`)**

- `"console"`, `"desktop"`, `"web"`, `"mobile"`, `"cloud"`, `"service"`, `"library"`, `"test"`, `"games"`, `"iot"`, `"extension"`, `"office"`, `"machinelearning"`, `"uwp"`, `"winui"`, `"other"`

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
		<DefaultName>DMNSN.Templates.Project.ConsoleApp</DefaultName>
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
⚙ Processing 'DMNSN.Templates.Project.ConsoleApp'...
📋 Template Name: DMNSN Console Application
👤 Author: DMNSN
🔢 Version: 8.0.17
🏷️ Tags: console,application,logging,dependency-injection,configuration
📂 Category: Console Applications
🎯 Project Type: CSharp
```

## Feedback and support

- File issues or feature requests in [Discussions](https://github.com/DevilDogTG/visualstudio-projects-template/discussions).
- Explore the sample code style in `src/DMNSN.Templates.Project.ConsoleApp`.
- Contributions and suggestions are welcome—help shape the next iteration of these templates.

