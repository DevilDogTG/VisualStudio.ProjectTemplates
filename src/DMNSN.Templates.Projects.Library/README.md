# DMNSN Class Library Template

A clean and modern .NET 8 class library template, designed to provide a robust starting point for building reusable components, business logic layers, or shared libraries.

This template is set up with sensible defaults and modern C# features, allowing you to start coding your library's logic right away.

## Key Features

- **.NET 8 & C# 12:** Utilizes the latest .NET and C# features, including file-scoped namespaces and primary constructors.
- **Nullable and Implicit Usings Enabled:** Comes with `Nullable` and `ImplicitUsings` enabled by default to promote modern, clean, and null-safe code.
- **Logging Abstractions:** Includes a reference to `Microsoft.Extensions.Logging.Abstractions` instead of a concrete logging implementation. This allows the consuming application to decide on the logging strategy, which is a best practice for libraries.
- **Ready to Package:** The `.csproj` file is pre-configured with metadata for creating a NuGet package, including properties for license, icon, and README.
- **Opinionated Code Style:** Follows the same consistent code style as the other DMNSN templates, with a corresponding `.editorconfig`.

## Getting Started

1.  **Add Your Code:**
    -   Delete the `Example.cs` and `Helpers/ExampleHelper.cs` files.
    -   Add your own classes, interfaces, and logic to the project. Organize your code into folders as needed.
2.  **Add Dependencies:**
    -   Add any necessary NuGet packages to the `.csproj` file.
3.  **Reference and Use:**
    -   Reference this library project from an application (like a Console App or Web API) to consume its functionality.
    -   Use dependency injection in the host application to inject services from this library (e.g., the `Example` class, which accepts an `ILogger`).
4.  **Publish as a NuGet Package (Optional):**
    -   Update the package metadata (e.g., `Authors`, `Description`, `PackageTags`) in the `.csproj` file.
    -   Run `dotnet pack` to create a `.nupkg` file in the `bin/Release` folder.

## Project Philosophy

- **Lean and Unobtrusive:** This template intentionally avoids including heavy dependencies or concrete implementations (like a specific database provider or logging framework). It provides abstractions and modern language features, leaving the final implementation choices to the consuming application.
- **Built for DI:** The example code demonstrates the use of primary constructors to accept dependencies like `ILogger`, encouraging a design that works well with dependency injection containers.