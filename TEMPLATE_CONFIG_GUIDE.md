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
  "defaultNamespace": "DMNSN.Templates.Project.ConsoleApp",
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

| Property | Type | Default | Description | Possible Values |
|----------|------|---------|-------------|-----------------|
| `author` | string | "Unknown" | The author of the template | Any string |
| `version` | string | "1.0.0" | Version of the template | Any version string |
| `tags` | array | [] | Tags for categorizing and filtering templates | See Built-in Tags section |
| `category` | string | "General" | Category for template organization | Any string |
| `projectType` | string | "CSharp" | **Main project type identifier** | `"CSharp"`, `"VisualBasic"`, `"Web"`, `"VC"` |
| `languageTag` | string | "C#" | Programming language tag for filtering | See Language Tags section |
| `platformTag` | string | "Windows" | Target platform tag for filtering | See Platform Tags section |
| `projectTypeTag` | string | "project" | Project type categorization for filtering | See Project Type Tags section |
| `sortOrder` | number | 1000 | Sort order in template lists | Any integer |
| `createNewFolder` | boolean | true | Whether to create a new folder for the project | `true`, `false` |
| `provideDefaultName` | boolean | true | Whether to provide a default project name | `true`, `false` |
| `locationField` | string | "Enabled" | Location field behavior | `"Enabled"`, `"Disabled"`, `"Hidden"` |
| `enableLocationBrowseButton` | boolean | true | Whether to show location browse button | `true`, `false` |
| `createInPlace` | boolean | true | Whether to create project in place | `true`, `false` |
| `requiredFrameworkVersion` | string | "4.0" | Minimum required framework version | Any .NET version string |
| `maxFrameworkVersion` | string | "" | Maximum supported framework version | Any .NET version string |
| `templateGroupIdentity` | string | "" | Template group identifier | Any unique string |
| `supportedLanguages` | array | ["C#"] | List of supported programming languages | Array of language strings |

## Valid Values Reference

### ProjectType (Main Categories)
The `projectType` field determines the main category where your template appears in Visual Studio:

- **`"CSharp"`** - C# projects (appears under Visual C# node)
- **`"VisualBasic"`** - Visual Basic projects (appears under Visual Basic node)  
- **`"Web"`** - Web projects (language defined by ProjectSubType)
- **`"VC"`** - Visual C++ projects

### Language Tags (Built-in)
Use these predefined language tags for proper localization:

- **`"csharp"`** or **`"C#"`** - C# language
- **`"visualbasic"`** - Visual Basic language
- **`"cpp"`** - C++ language
- **`"fsharp"`** - F# language
- **`"javascript"`** - JavaScript language
- **`"typescript"`** - TypeScript language
- **`"python"`** - Python language
- **`"java"`** - Java language
- **`"querylanguage"`** - Query Language
- **`"xaml"`** - XAML language

### Platform Tags (Built-in)
Use these predefined platform tags for proper categorization:

- **`"windows"`** - Windows platform
- **`"android"`** - Android platform
- **`"ios"`** - iOS platform
- **`"linux"`** - Linux platform
- **`"macos"`** - macOS platform
- **`"tvos"`** - tvOS platform
- **`"xbox"`** - Xbox platform
- **`"windowsappsdk"`** - Windows App SDK
- **`"azure"`** - Azure platform

### Project Type Tags (Built-in)
Use these predefined project type tags for filtering:

- **`"console"`** - Console applications
- **`"desktop"`** - Desktop applications
- **`"web"`** - Web applications
- **`"mobile"`** - Mobile applications
- **`"cloud"`** - Cloud applications
- **`"service"`** - Service applications
- **`"library"`** - Library projects
- **`"test"`** - Test projects
- **`"games"`** - Game projects
- **`"iot"`** - IoT projects
- **`"extension"`** - Extension projects
- **`"office"`** - Office applications
- **`"machinelearning"`** - Machine Learning projects
- **`"uwp"`** - UWP applications
- **`"winui"`** - WinUI applications
- **`"other"`** - Other project types

### Custom Tags
You can also create custom tags by using any string value. However, built-in tags provide better localization and Visual Studio integration.

## Understanding ProjectType vs ProjectCategory vs Tags

### ProjectType (Required)
- **Purpose**: Determines the **main language/technology category** in Visual Studio's New Project dialog
- **Values**: `"CSharp"`, `"VisualBasic"`, `"Web"`, `"VC"` (limited set)
- **Effect**: Places template under specific language node in project tree
- **Example**: `"CSharp"` puts template under "Visual C#" category

### ProjectCategory (Optional - Custom Property)
- **Purpose**: Custom organizational category for grouping templates
- **Values**: Any string (e.g., "Console", "Web API", "Desktop", "Service")
- **Effect**: Used for internal organization, not directly visible in VS dialog
- **Example**: `"Console"` for console application templates

### Tags (languageTag, platformTag, projectTypeTag)
- **Purpose**: **Filtering and searchability** in Visual Studio's New Project dialog
- **Values**: Built-in predefined tags (recommended) or custom strings
- **Effect**: Appear as filter chips and searchable metadata
- **Example**: `"console"` tag makes template findable when user searches "console"

### Best Practice Combinations

**Console Application:**
```json
{
  "projectType": "CSharp",
  "category": "Console Applications",
  "languageTag": "csharp",
  "platformTag": "windows", 
  "projectTypeTag": "console"
}
```

**Web API:**
```json
{
  "projectType": "CSharp",
  "category": "Web APIs",
  "languageTag": "csharp",
  "platformTag": "windows",
  "projectTypeTag": "web"
}
```

**Windows Service:**
```json
{
  "projectType": "CSharp", 
  "category": "Services",
  "languageTag": "csharp",
  "platformTag": "windows",
  "projectTypeTag": "service"
}
```

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
    <DefaultName>DMNSN.Templates.Project.ConsoleApp</DefaultName>
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
⚙ Processing 'DMNSN.Templates.Project.ConsoleApp'...
📋 Template Name: DMNSN Console Application
👤 Author: DMNSN
🔢 Version: 1.0.0
🏷️ Tags: Console,Application,Logging,DependencyInjection,Configuration
📂 Category: Console
🎯 Project Type: CSharp
```

This enhanced configuration system provides a professional and comprehensive way to manage Visual Studio project templates with rich metadata and improved user experience.
