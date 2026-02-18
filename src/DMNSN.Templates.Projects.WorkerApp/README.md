# DMNSN Worker Service Template

An opinionated .NET 8 template for building robust, long-running background services and Windows Services.

This template provides a production-ready starting point for worker processes, complete with structured logging, dependency injection, and proper service lifetime management.

## Key Features

- **.NET 8 Worker Service:** Built on the modern .NET Worker SDK (`Microsoft.NET.Sdk.Worker`).
- **Cross-Platform:** Includes support for running as a Windows Service (`AddWindowsService`) or a Linux systemd daemon (`AddSystemd`).
- **Structured Logging:** Integrated with [Serilog](https://serilog.net/) for powerful structured logging, configured via `logsettings.json`.
- **Dependency Injection:** Fully utilizes `Microsoft.Extensions.Hosting` for DI. It demonstrates the correct pattern for resolving scoped services within a long-running singleton service.
- **Graceful Shutdown:** The `WorkerService` correctly handles cancellation tokens to allow for graceful shutdown of the background task.
- **Scoped Service Resolution:** The main execution loop in `WorkerService` shows the best-practice use of `IServiceScopeFactory` to create a new DI scope for each iteration. This prevents memory leaks and ensures services with a scoped or transient lifetime are handled correctly.

## Getting Started

1.  **Restore Dependencies:** Run `dotnet restore` to download the required NuGet packages.
2.  **Customize Configuration:**
    -   Modify `appsettings.json` to define your application's configuration.
    -   Adjust `logsettings.json` to control log levels and output formats.
3.  **Implement Your Worker Logic:**
    -   The main execution logic is in the `ExecuteAsync` method of `WorkerService.cs`.
    -   The template calls `IAppService.RunProcessAsync()` within the loop. You can replace this with your own services and logic.
    -   Adjust the `Task.Delay()` at the end of the loop to control how frequently your worker performs its task.
4.  **Add Your Services:**
    -   Create your own services to encapsulate the work your worker needs to do.
    -   Register them in `Program.cs`. Remember to register them with a `Scoped` or `Transient` lifetime if they are resolved within the `WorkerService` loop.
5.  **Run the Application:**
    -   **As a console app:** Run the project directly from your IDE or with `dotnet run`. This is useful for development and debugging.
    -   **As a Windows Service:** Publish the application and use `sc.exe create` to install it as a Windows Service.
    -   **As a systemd service:** Publish the application for Linux and create a service unit file to run it with systemd.

## Core Dependencies

- `Microsoft.Extensions.Hosting`: The core library for creating worker services in .NET.
- `Microsoft.Extensions.Hosting.WindowsServices`: Provides Windows Service integration.
- `Microsoft.Extensions.Hosting.Systemd`: Provides Linux systemd integration.
- `Serilog.Extensions.Hosting`: For integrating Serilog with the .NET hosting infrastructure.
- `DMNSN.Core`: A shared library providing core functionalities and settings.