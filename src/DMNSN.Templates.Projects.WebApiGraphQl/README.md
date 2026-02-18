# DMNSN Web API (GraphQL) Template

An opinionated .NET 8 Web API template for building high-performance GraphQL services, powered by [Hot Chocolate](https://chillicream.com/docs/hotchocolate).

This template provides a production-ready starting point with a complete setup for structured logging, dependency injection, configuration, and a code-first GraphQL schema.

## Key Features

- **.NET 8 & ASP.NET Core:** Built on the latest version of .NET for building modern, high-performance web services.
- **GraphQL with Hot Chocolate:** Comes with Hot Chocolate, a powerful and feature-rich GraphQL server for .NET. The template is configured for a code-first approach.
- **Structured Logging:** Integrated with [Serilog](https://serilog.net/) for structured logging. Includes middleware to enrich logs with a correlation ID for easier request tracing.
- **Dependency Injection:** Fully utilizes `Microsoft.Extensions.DependencyInjection` to manage services and their dependencies. Services are registered in `Program.cs` and can be injected directly into GraphQL resolvers.
- **Validated Configuration:** Uses the `IOptions` pattern with data annotations and custom validation to ensure that configuration from `appsettings.json` is valid on application startup.
- **Correlation ID Middleware:** Includes a custom middleware (`UseCorrelationIdMiddleware`) that establishes a unique correlation ID for each HTTP request, which is then available for logging and services.
- **Example Schema:** Provides an example `QueryType` and `MutationType` to demonstrate how to define your GraphQL schema, resolve fields, and inject services.

## Getting Started

1.  **Restore Dependencies:** Run `dotnet restore` to download the required NuGet packages.
2.  **Customize Configuration:**
    -   Modify `appsettings.json` to define your application's configuration, such as connection strings or service URLs.
    -   Adjust `logsettings.json` to control log levels and output formats.
3.  **Define Your GraphQL Schema:**
    -   Add new fields to `GraphQl/Types/QueryType.cs` for queries.
    -   Add new fields to `GraphQl/Types/MutationType.cs` for mutations.
    -   Create new types in the `GraphQl/Types` folder to represent the data in your schema.
4.  **Implement Your Business Logic:**
    -   Create or update services in the `Services` folder to handle the business logic for your GraphQL resolvers.
    -   Register your new services in `Program.cs`.
    -   Inject your services into the resolvers within your `QueryType` or `MutationType` classes using `context.Service<T>()`.
5.  **Run the Application:**
    -   Run the project from your IDE or use `dotnet run`.
    -   Navigate to `/graphql` in your browser to open the Banana Cake Pop GraphQL IDE.
    -   Execute a sample query:
        ```graphql
        query {
          example(message: "Test")
          version
          correlationId
        }
        ```

## Core Dependencies

- `HotChocolate.AspNetCore`: The core library for hosting a GraphQL server on ASP.NET Core.
- `Serilog.AspNetCore`: For integrating Serilog with ASP.NET Core's logging system.
- `DMNSN.AspNetCore.Middlewares.CorrelationId`: Custom middleware for request correlation.
- `DMNSN.Core`: A shared library providing core functionalities and settings.
- `NUlid`: For generating fast, sortable, and URL-safe unique identifiers.