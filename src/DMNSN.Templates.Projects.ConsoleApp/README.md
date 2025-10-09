# DMNSN Console Application Template

A modern and opinionated .NET 8 console application template designed for building robust, production-ready command-line tools and services.

This template provides a solid foundation with pre-configured structured logging, dependency injection, and application configuration, allowing you to focus on business logic instead of boilerplate setup.

## Key Features

- **.NET 8 & C# 12:** Built on the latest version of .NET using modern C# features like top-level statements and file-scoped namespaces.
- **Structured Logging:** Comes with [Serilog](https://serilog.net/) pre-configured to write to the console and rolling log files. Logging behavior is defined in `logsettings.json`.
- **Dependency Injection:** Uses `Microsoft.Extensions.Hosting` to provide a familiar DI pattern, making it easy to manage services and their dependencies. Services are registered in `Program.cs`.
- **Configuration Management:** Application settings are loaded from `appsettings.json` with support for environment-specific overrides (e.g., `appsettings.Development.json`). Settings are strongly-typed and available via `IOptions<T>`.
- **Command-Line Argument Parsing:** Integrated with the [CommandLineParser](https://github.com/commandlineparser/commandline) library to provide a declarative way to define and handle command-line arguments and verbs.
- **Opinionated Defaults:** Includes a `.editorconfig` for consistent code style and sensible project settings for nullability and implicit usings.

## Getting Started

1.  **Restore Dependencies:** Run `dotnet restore` to download the required NuGet packages.
2.  **Customize Configuration:**
    -   Modify `appsettings.json` to define your application's configuration.
    -   Adjust `logsettings.json` to control log levels, output templates, and file paths.
3.  **Define Command-Line Interface:**
    -   Add or modify classes in the `ProgramArgs.cs` file to define your CLI verbs and options using `[Verb]` and `[Option]` attributes.
    -   Implement the logic for each command in the `StartApplication.cs` service.
4.  **Implement Your Logic:**
    -   Add your own services to the `Services` folder.
    -   Register your services in `Program.cs`.
    -   Inject and use your services in `StartApplication.cs` or other parts of the application.
5.  **Run the Application:**
    -   Run the project from your IDE or use `dotnet run` from the command line.
    -   Pass arguments to test your command-line parsing logic (e.g., `dotnet run -- --help`).

## Core Dependencies

This template integrates several popular libraries to provide its core functionality:

- `Microsoft.Extensions.Hosting`: For dependency injection, configuration, and application lifetime management.
- `Serilog`: For flexible and structured logging.
- `Serilog.Sinks.Console` & `Serilog.Sinks.File`: For directing log output.
- `Serilog.Settings.Configuration`: For reading Serilog configuration from `IConfiguration`.
- `CommandLineParser`: For parsing command-line arguments.
- `Newtonsoft.Json`: For JSON serialization/deserialization.
- `DMNSN.Core`: A shared library providing core functionalities and settings.