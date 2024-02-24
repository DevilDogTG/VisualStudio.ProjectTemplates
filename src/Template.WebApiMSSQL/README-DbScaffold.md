# Database-First reverse engineering with Entity Framework Core

The `Scaffold-DbContext` command is used to scaffold the database. The command is used to create the entity classes and the `DbContext` class for the database.

## Usage

Use the following command to scaffold the database in NuGet Package Manager Console.

``` powershell
Scaffold-DbContext -Connection "Name=ConnectionStrings:Default" -Provider Microsoft.EntityFrameworkCore.SqlServer -Context AppDbContext -ContextDir Db -OutputDir Db/Models [-Tables <String[]>] -Force
```

Note: Replace the placeholders with the actual values.

### Parameters

- `-Connection`: The connection string to the database.
- `-Provider`: The database provider. In this case, it is `Microsoft.EntityFrameworkCore.SqlServer`.
- `-Context`: The name of the `DbContext` class.
- `-ContextDir`: The directory where the `DbContext` class will be created.
- `-OutputDir`: The directory where the entity classes will be created.
- `-Tables`: The tables to scaffold. If not specified, all tables will be scaffolded.
- `-Force`: Overwrite existing files.

## Reference

- [Scaffold-DbContext command](https://docs.microsoft.com/en-us/ef/core/cli/powershell#scaffold-dbcontext)
- [Connection Strings](https://docs.microsoft.com/en-us/ef/core/miscellaneous/connection-strings)
- [Protecting connection strings and other configuration information](https://docs.microsoft.com/en-us/ef/core/miscellaneous/connection-strings#protecting-connection-strings-and-other-configuration-information)