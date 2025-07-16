# Enhanced Template Configuration Guide

This guide explains how to use the enhanced template configuration system for Visual Studio project templates.

## Overview

The enhanced template configuration system allows you to define comprehensive metadata for your Visual Studio project templates through a `template.config.json` file. This configuration is automatically processed by the `Export-DmnsnTemplate.ps1` script to generate feature-rich `.vstemplate` files.

## Configuration File Structure

### Basic Configuration

```json
{
  "name": "Template Display Name",
  "description": "Detailed description of the template",
  "defaultNamespace": "YourProject.Namespace"
}
```

### Enhanced Configuration

```json
{
  "name": "DMNSN Console Application",
  "description": "A modern console application template with logging, dependency injection, and configuration support",
  "defaultNamespace": "DMNSN.ConsoleApps",
  "author": "DMNSN",
  "version": "1.0.0",
  "tags": ["Console", "Application", "Logging", "DependencyInjection", "Configuration"],
  "category": "Console",
  "projectType": "CSharp",
  "languageTag": "C#",
  "platformTag": "Console",
  "projectTypeTag": "console",
  "sortOrder": 1000,
  "createNewFolder": true,
  "provideDefaultName": true,
  "locationField": "Enabled",
  "enableLocationBrowseButton": true,
  "createInPlace": true,
  "requiredFrameworkVersion": "8.0",
  "supportedLanguages": ["C#"],
  "templateGroupIdentity": "DMNSN.Templates",
  "maxFrameworkVersion": "8.0"
}
```

## Configuration Properties

### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | string | The display name of the template in Visual Studio |
| `description` | string | A detailed description of what the template provides |
| `defaultNamespace` | string | The default namespace used in generated projects |

### Optional Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `author` | string | "Unknown" | The author of the template |
| `version` | string | "1.0.0" | Version of the template |
| `tags` | array | [] | Tags for categorizing and filtering templates |
| `category` | string | "General" | Category for template organization |
| `projectType` | string | "CSharp" | Project type identifier |
| `languageTag` | string | "C#" | Programming language tag |
| `platformTag` | string | "Windows" | Target platform tag |
| `projectTypeTag` | string | "project" | Project type categorization |
| `sortOrder` | number | 1000 | Sort order in template lists |
| `createNewFolder` | boolean | true | Whether to create a new folder for the project |
| `provideDefaultName` | boolean | true | Whether to provide a default project name |
| `locationField` | string | "Enabled" | Location field behavior |
| `enableLocationBrowseButton` | boolean | true | Whether to show location browse button |
| `createInPlace` | boolean | true | Whether to create project in place |
| `requiredFrameworkVersion` | string | "4.0" | Minimum required framework version |
| `maxFrameworkVersion` | string | "" | Maximum supported framework version |
| `templateGroupIdentity` | string | "" | Template group identifier |
| `supportedLanguages` | array | ["C#"] | List of supported programming languages |

## Generated VSTemplate Elements

The configuration properties are mapped to the following VSTemplate elements:

### Core Template Data
- `name` → `<Name>`
- `description` → `<Description>`
- `projectType` → `<ProjectType>`
- `sortOrder` → `<SortOrder>`
- `createNewFolder` → `<CreateNewFolder>`
- `defaultNamespace` → `<DefaultName>`
- `provideDefaultName` → `<ProvideDefaultName>`
- `locationField` → `<LocationField>`
- `enableLocationBrowseButton` → `<EnableLocationBrowseButton>`
- `createInPlace` → `<CreateInPlace>`

### Enhanced Metadata
- `author` → `<Author>`
- `version` → `<Version>`
- `tags` → `<ProjectSubType>` (comma-separated)
- `category` → `<ProjectCategory>`
- `languageTag` → `<LanguageTag>`
- `platformTag` → `<PlatformTag>`
- `projectTypeTag` → `<ProjectTypeTag>`
- `requiredFrameworkVersion` → `<RequiredFrameworkVersion>`
- `maxFrameworkVersion` → `<MaxFrameworkVersion>`
- `templateGroupIdentity` → `<TemplateGroupID>`
- `supportedLanguages` → `<SupportedLanguages>` (comma-separated)

## Example Generated VSTemplate

```xml
<VSTemplate Version="3.0.0" xmlns="http://schemas.microsoft.com/developer/vstemplate/2005" Type="Project">
  <TemplateData>
    <Name>DMNSN Console Application</Name>
    <Description>A modern console application template with logging, dependency injection, and configuration support</Description>
    <ProjectType>CSharp</ProjectType>
    <SortOrder>1000</SortOrder>
    <CreateNewFolder>true</CreateNewFolder>
    <DefaultName>DMNSN.ConsoleApps</DefaultName>
    <ProvideDefaultName>true</ProvideDefaultName>
    <LocationField>Enabled</LocationField>
    <EnableLocationBrowseButton>true</EnableLocationBrowseButton>
    <CreateInPlace>true</CreateInPlace>
    <Icon>__TemplateIcon.ico</Icon>
    <PreviewImage>__TemplatePreview.png</PreviewImage>
    <Author>DMNSN</Author>
    <ProjectSubType>Console,Application,Logging,DependencyInjection,Configuration</ProjectSubType>
    <ProjectCategory>Console</ProjectCategory>
    <LanguageTag>C#</LanguageTag>
    <PlatformTag>Console</PlatformTag>
    <ProjectTypeTag>console</ProjectTypeTag>
    <RequiredFrameworkVersion>8.0</RequiredFrameworkVersion>
    <MaxFrameworkVersion>8.0</MaxFrameworkVersion>
    <TemplateGroupID>DMNSN.Templates</TemplateGroupID>
    <SupportedLanguages>C#</SupportedLanguages>
  </TemplateData>
  <TemplateContent>
    <!-- Project files and structure -->
  </TemplateContent>
</VSTemplate>
```

## Usage

1. Create or update your `template.config.json` file in your project template directory
2. Run the export script: `.\scripts\Export-DmnsnTemplate.ps1`
3. The script will generate an enhanced `.vstemplate` file with all the configured properties
4. Install the generated ZIP file in Visual Studio

## Benefits

- **Better Organization**: Templates are properly categorized and tagged
- **Enhanced Discoverability**: Rich metadata helps users find the right template
- **Professional Appearance**: Templates include author information and version details
- **Framework Compatibility**: Specify supported framework versions
- **Improved User Experience**: Better descriptions and categorization in Visual Studio

## Script Output

When running the export script, you'll see enhanced logging that shows the applied configuration:

```
⚙ Processing 'DMNSN.ConsoleApps'...
📋 Template Name: DMNSN Console Application
👤 Author: DMNSN
🔢 Version: 1.0.0
🏷️ Tags: Console,Application,Logging,DependencyInjection,Configuration
📂 Category: Console
🎯 Project Type: CSharp
```

This enhanced configuration system provides a professional and comprehensive way to manage Visual Studio project templates with rich metadata and improved user experience.
