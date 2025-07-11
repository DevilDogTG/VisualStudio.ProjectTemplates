# Visual Studio Template for creating a new project

This project is a Visual Studio template for creating a new project. It is based on personal used and is not intended to be a one-size-fits-all solution. It is intended to be a starting point for a new project.

Any comment and suggestion are welcome. Please use the [Discussions](https://github.com/DevilDogTG/visualstudio-projects-template/discussions) section to report any problem or to suggest any improvement.

> **Note** This is individual maintained project. Maybe I will not be able to respond to all issues. But I will try to do my best.

Project is based on:
- .NET 8.0
- Use `Serilog` as logging system
- Database-first design

Various project types including:
- Console Application
- Web API
- Worker Service (Windows Service)

## Dependencies

Thanks to the community, the template uses some dependencies to make the development process easier.

- [Serilog](https://serilog.net/)
	- [Serilog.Enrichers.AspNetCore.RequestHeader](https://github.com/DevilDogTG/serilog-enrichers-aspnetcore)
	- [Serilog.Enrichers.Environment](https://github.com/serilog/serilog-enrichers-environment)
- [Entity Framework Core](https://docs.microsoft.com/en-us/ef/core/)
- [EFCore.BulkExtension](https://github.com/borisdj/EFCore.BulkExtensions)
- [Newtonsoft.Json](https://www.newtonsoft.com/json)

## Concepts

Following we need to explain some concepts used in the template.

### Serilog

The template uses `Serilog` as the logging system. It is a flexible and easy-to-use logging library for .NET. It is easy to configure and can be used in various scenarios.

Additional on Web API projects, the template uses `Serilog.Enrichers.AspNetCore.RequestHeader` to enrich the log with the request headers (currently support only correlationId).

Performance logging is also included in the template. It logs the duration of the request and the response status code. This job has job been done by `PerformanceLoggingMiddleware` class.

### Database-first design

The template uses a database-first design. This means that the database is designed first and then the code is generated from the database. This is done using Entity Framework Core.

Currently, the template uses SQL Server as the database. The database is then imported into the project using the `Scaffold-DbContext` command.

> I added some example commands usage in `README-DbScaffold.md` file. Only for reference.

### Dependency Injection

The template uses dependency injection to manage the application's components. This is done using the built-in dependency injection system in .NET.

For more information, see [Dependency injection in .NET](https://docs.microsoft.com/en-us/dotnet/core/extensions/dependency-injection).

## Usage

To install the template, just copy files in folder `export` to the following directory:

```cmd
%USERPROFILE%\Documents\Visual Studio 2022\Templates\ProjectTemplates
```

**Note** that you need to replace `Visual Studio 2022` with the version of Visual Studio you are using.

Or run the following command in `PowerShell` to copy the files:

```powershell
Copy-Item -Path .\export\* -Destination "$env:USERPROFILE\Documents\Visual Studio 2022\Templates\ProjectTemplates" -Recurse -Force
```

**Note** that you need to replace `Visual Studio 2022` with the version of Visual Studio you are using.

Then, you can create a new project using the template in Visual Studio.


For details on the coding style used in the sample console app, see [src/DMNSN.ConsoleApps/README.md](src/DMNSN.ConsoleApps/README.md).

