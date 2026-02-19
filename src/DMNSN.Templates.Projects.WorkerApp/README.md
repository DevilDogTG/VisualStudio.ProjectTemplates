# DMNSN.Templates.Projects.Library

Opinionated .NET 8 class library template with nullable enabled, analyzers-ready layout, and packaging metadata.

## Features

- `net8.0`, `Nullable` enabled, and `ImplicitUsings` on by default.
- File-scoped namespaces and modern C# patterns.
- Ready-to-publish packaging metadata (`PackageIcon`, `PackageReadmeFile`, `PackageLicenseFile`).
- Consistent code style across DMNSN templates.

## Suggested setup

- Add analyzers like `Microsoft.CodeAnalysis.NetAnalyzers` or `StyleCop.Analyzers` if desired.
- Use `InternalsVisibleTo` in `Directory.Build.props` when sharing internals with test projects.
- Adopt `Serilog` only if your library performs logging; otherwise depend on `ILogger<T>` abstractions.

## Getting started

- Add your domain classes, services, and extension methods.
- Reference this library from your app or other templates.
- Publish the template and create a new project in Visual Studio using the DMNSN Class Library template.

