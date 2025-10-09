# DMNSN Web API (REST) Template

An opinionated .NET 8 template for building robust and scalable RESTful APIs using ASP.NET Core.

This template provides a production-ready foundation with a complete setup for structured logging, dependency injection, configuration, and a conventional controller-based architecture.

## Key Features

- **.NET 8 & ASP.NET Core:** Built on the latest version of .NET for creating high-performance web services.
- **RESTful API with Controllers:** Uses the familiar and powerful controller-based pattern for defining API endpoints.
- **Structured Logging:** Integrated with [Serilog](https://serilog.net/) for structured logging. Includes middleware to enrich logs with a correlation ID for easier request tracing across services.
- **Dependency Injection:** Fully utilizes `Microsoft.Extensions.DependencyInjection` to manage services and their dependencies. Services can be injected directly into controllers.
- **Validated Configuration:** Uses the `IOptions` pattern with data annotations and custom validation to ensure that configuration from `appsettings.json` is valid on application startup.
- **Correlation ID Middleware:** Includes a custom middleware (`UseCorrelationIdMiddleware`) that establishes a unique correlation ID for each HTTP request. This ID is easily accessible in controllers via the `DefaultControllerBase`.
- **Base Controller:** Provides a `DefaultControllerBase` that abstracts away common boilerplate, such as accessing the correlation ID, logger, and application settings.

## Getting Started

1.  **Restore Dependencies:** Run `dotnet restore` to download the required NuGet packages.
2.  **Customize Configuration:**
    -   Modify `appsettings.json` to define your application's configuration, such as connection strings or external service URLs.
    -   Adjust `logsettings.json` to control log levels, output formats, and file paths.
3.  **Create Your Controllers:**
    -   Add new controllers to the `Controllers` folder.
    -   Inherit from `DefaultControllerBase` to get easy access to the logger, correlation ID, and app settings.
4.  **Implement Your Business Logic:**
    -   Add your business logic in separate service classes (e.g., in a `Services` folder).
    -   Register your services in `Program.cs`.
    -   Inject your services into the constructors of your controllers.
5.  **Run the Application:**
    -   Run the project from your IDE or use `dotnet run`.
    -   The API will be available at the URLs specified in `Properties/launchSettings.json`.
    -   You can test the example endpoint by sending a GET request to `/api/example`.

## Core Dependencies

- `Serilog.AspNetCore`: For integrating Serilog with ASP.NET Core's logging system.
- `DMNSN.AspNetCore.Middlewares.CorrelationId`: Custom middleware for request correlation.
- `DMNSN.Core`: A shared library providing core functionalities and settings.
- `Newtonsoft.Json`: For JSON serialization/deserialization.