# DMNSN.Templates.Projects.ConsoleApp

A modern .NET 8 console application template with structured logging, dependency injection, rich configuration, and opinionated defaults.

## Features

- Top-level statements in `Program.cs` configure the host and Serilog without an explicit `Main`.
- File-scoped namespaces and C# primary constructors keep services compact and DI-friendly.
- Command line parsing via `CommandLineParser` with `[Verb]` and `[Option]` attributes.
- Strongly-typed configuration via `IOptionsMonitor<T>` with live reload.
- `IDisposable` cleanup for services that subscribe to change tokens.
- `.editorconfig` tuned to reduce nullability noise while keeping safety.

## Dependencies

- Serilog (+ Console/File sinks, Settings.Configuration, Enrichers.Environment)
- Microsoft.Extensions.Hosting / DependencyInjection
- CommandLineParser
- Newtonsoft.Json

## Getting started

- Restore and build. Run the project to see structured logs and DI wiring in action.
- Update `appsettings.json` and `logsettings.json` to customize logging and configuration.
- Add verbs and options to expand the CLI surface area.

## Packaging

This template ships with packaging metadata (`PackageIcon`, `PackageReadmeFile`, `PackageLicenseFile`) to support distribution through local VS template folders.

