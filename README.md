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

## Scripts for Template Management

This project includes PowerShell scripts to automate template creation, packaging, and publishing for `dotnet new`.

> **Version ownership:** The package version is set once — when a feature PR is created via `Feature-PullRequest.ps1`. All downstream steps (export, develop publish, release) consume that version without changing it.

### 1. Creating a feature PR (`Feature-PullRequest.ps1`)

Run this when your feature branch is ready for review. It bumps the version in `templatepack.config.json`, commits it, pushes the branch, and opens a PR targeting `develop`.

```powershell
# Default — bump patch version (e.g. 10.0.2 → 10.0.3)
.\scripts\templates\Feature-PullRequest.ps1

# Bump minor version (e.g. 10.0.2 → 10.1.0)
.\scripts\templates\Feature-PullRequest.ps1 -BumpMinor

# Bump major version (e.g. 10.0.2 → 11.0.0)
.\scripts\templates\Feature-PullRequest.ps1 -BumpMajor

# Open as a draft PR
.\scripts\templates\Feature-PullRequest.ps1 -Draft
```

**Key Parameters:**
- `-BumpMinor`: Bumps the minor version, resets patch to 0.
- `-BumpMajor`: Bumps the major version, resets minor and patch to 0.
- `-Version <string>`: Explicit target version, skips auto-bump.
- `-Title <string>`: PR title. Supports `{version}`, `{branch}`, `{tag}` placeholders.
- `-Body <string>`: PR body text. Supports the same placeholders.
- `-Draft`: Opens the PR as a draft.

### 2. Exporting and Packing (`Export-DotnetCliTemplate.ps1`)

This is the primary script for creating a `.nupkg` template package from the source projects. It reads `template.config.json` from each project, generates `template.json` files, and bundles them into a NuGet package.

**Common Usage:**

- **Export all templates:**
  ```powershell
  .\scripts\templates\Export-DotnetCliTemplate.ps1
  ```

- **Export specific templates:**
  ```powershell
  .\scripts\templates\Export-DotnetCliTemplate.ps1 -Projects "ConsoleApp", "WebApiRest"
  ```

- **Set a specific package version:**
  ```powershell
  .\scripts\templates\Export-DotnetCliTemplate.ps1 -Version 1.2.3
  ```

- **Preview changes without writing files:**
  ```powershell
  .\scripts\templates\Export-DotnetCliTemplate.ps1 -DryRun
  ```

**Key Parameters:**
- `-Projects <string[]>`: A list of project names to export (e.g., "ConsoleApp"). If omitted, all projects in `src` are exported.
- `-Version <string>`: Overrides the auto-incremented package version.
- `-DryRun`: Shows what would happen without actually creating files.
- `-NoPack`: Prepares the template folders in `output` but stops before creating a `.nupkg`.
- `-InstallLatestPackage`: After creating the package, it uninstalls any existing version and installs the new one.
- `-TemplatesPath <string>`: Overrides the staging folder for generated templates (default: `output`).
- `-PackagesPath <string>`: Controls where `.nupkg` files are written (default: `artifacts`).
- `-AggregateConfigPath <string>`: Path to the running version config (default: `templatepack.config.json`).
- `-LogPath <string>`: Specifies a path for the log file.

### 2. Publishing to NuGet (`Nuget-Published.ps1`)

This script automates the publish pipeline in two modes: **develop** (pre-release) and **release** (stable).

#### Develop mode

Publishes a `-dev.x` pre-release to NuGet for testing. Requires a NuGet API key.

```powershell
# Key resolved automatically from the NUGET_API_KEY environment variable
.\scripts\templates\Nuget-Published.ps1 -Mode develop

# Or pass the key explicitly
.\scripts\templates\Nuget-Published.ps1 -Mode develop -NuGetApiKey "your-key"
```

What it does:
1. Resolves `NUGET_API_KEY` (parameter → env var). Stops if missing.
2. Computes the next `-dev.x` version (`10.0.2` → `10.0.3-dev.1`, `10.0.3-dev.1` → `10.0.3-dev.2`).
3. Exports and packs the template bundle.
4. Tags the dev version in git and pushes the tag.
5. Publishes the `.nupkg` to NuGet.org.

#### Release mode

Creates a release branch + PR. Tagging and NuGet publish happen automatically after the PR is merged via GitHub Actions.

```powershell
# Requires the gh CLI to be installed and authenticated
.\scripts\templates\Nuget-Published.ps1 -Mode release
```

What it does:
1. Computes the clean release version (strips `-dev.x`, e.g. `10.0.3-dev.5` → `10.0.3`).
2. Creates a `release-{version}` branch.
3. Exports and packs the template bundle with the release version.
4. Auto-generates a `CHANGELOG.md` entry from git commits since the last release tag.
5. Commits `templatepack.config.json` + `CHANGELOG.md` to the release branch.
6. Pushes the branch and opens a PR targeting `main` via the `gh` CLI.

After the PR is merged, the **GitHub Actions** workflow (`.github/workflows/publish-release.yml`) automatically:
- Tags `v{version}` and pushes the tag.
- Merges `main` back into `develop`.
- Packs and publishes `DMNSN.ProjectTemplates.{version}.nupkg` to NuGet.org.

**Key Parameters:**
- `-Mode <develop|release>`: Required. Selects the publish mode.
- `-NuGetApiKey <string>`: NuGet API key override (develop mode). Falls back to `NUGET_API_KEY` env var.
- `-Version <string>`: Override the computed version in either mode.
- `-CommitMessage <string>`: Custom release-branch commit message. Supports `{version}` and `{tag}`.
- `-PrTitle <string>`: Custom PR title (release mode).

## GitHub Actions — Secrets setup

Two repository secrets are required for the automated release workflows.

### Step 1 — Add `NUGET_API_KEY`

This key is used by `publish-release.yml` to push the `.nupkg` to NuGet.org.

1. Go to [nuget.org](https://www.nuget.org/) → sign in → click your avatar → **API Keys**.
2. Click **Create** and configure:
   - **Key name**: e.g. `github-actions-dmnsn`
   - **Expiration**: choose a suitable duration (max 365 days)
   - **Glob pattern**: `DMNSN.ProjectTemplates*`
   - **Packages**: select **Push new packages and package versions**
3. Click **Create** and **copy the key immediately** (it won't be shown again).
4. In this GitHub repository go to **Settings → Secrets and variables → Actions → New repository secret**:
   - **Name**: `NUGET_API_KEY`
   - **Secret**: paste the key from step 3.

### Step 2 — Add `GH_PAT`

A Personal Access Token is required for two things:
- **`release-gate.yml`**: auto-merging the PR — merges made with `GITHUB_TOKEN` do **not** fire subsequent workflow runs, so a PAT is essential to trigger `publish-release.yml`.
- **`publish-release.yml`**: pushing the merged-back commit to `develop` (needed if the branch has protection rules).

#### Create the PAT (Fine-grained, recommended)

1. Go to [github.com/settings/tokens](https://github.com/settings/tokens) → **Fine-grained tokens** → **Generate new token**.
2. Configure:
   - **Token name**: e.g. `dmnsn-release-automation`
   - **Expiration**: choose a duration (e.g. 1 year)
   - **Repository access**: only this repository (`VisualStudio.ProjectTemplates`)
   - **Repository permissions**:
     | Permission | Access |
     |---|---|
     | Contents | Read and write |
     | Pull requests | Read and write |
     | Metadata | Read (auto-selected) |
3. Click **Generate token** and **copy it immediately**.
4. In the repository go to **Settings → Secrets and variables → Actions → New repository secret**:
   - **Name**: `GH_PAT`
   - **Secret**: paste the token.

### Verification

Once both secrets are set, navigate to **Settings → Secrets and variables → Actions** and confirm both `NUGET_API_KEY` and `GH_PAT` appear in the repository secrets list.

### Workflow overview

```
┌─────────────────────────────────────────────────────────────────┐
│  FEATURE  (feature/* branch)                                    │
│                                                                 │
│  developer runs: Feature-PullRequest.ps1 [-BumpMinor|-BumpMajor]│
│    → bumps version in templatepack.config.json                  │
│    → commits, pushes, opens PR  feature/* → develop            │
│                           │                                     │
│              reviewer approves the PR                           │
│                           │                                     │
│                           ▼                                     │
│         [feature-gate.yml]                                      │
│            ✓ conflict check with develop                        │
│            ✓ auto-merges PR → develop  (uses GH_PAT)           │
└─────────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┘  (optionally: develop -dev.x builds)
                │  developer runs: Nuget-Published.ps1 -Mode develop
                │    → tags v{version}-dev.x, publishes pre-release
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│  RELEASE  (release/* branch)                                    │
│                                                                 │
│  developer runs: Nuget-Published.ps1 -Mode release              │
│    → strips -dev.x, creates release-{version} branch           │
│    → generates CHANGELOG.md entry                               │
│    → commits, pushes, opens PR  release-{version} → main       │
│                           │                                     │
│              reviewer approves the PR                           │
│                           │                                     │
│                           ▼                                     │
│         [release-gate.yml]                                      │
│            ✓ conflict check with develop                        │
│            ✓ auto-merges PR → main  (uses GH_PAT)              │
│                           │                                     │
│                           ▼                                     │
│         [publish-release.yml]                                   │
│            ✓ export & pack .nupkg                               │
│            ✓ git tag v{version}                                 │
│            ✓ merge main → develop                               │
│            ✓ dotnet nuget push                                  │
└─────────────────────────────────────────────────────────────────┘
```

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

