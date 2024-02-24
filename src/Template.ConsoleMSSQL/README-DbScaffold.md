# Database-First reverse engineering with Entity Framework Core

The `Scaffold-DbContext` command is used to scaffold the database. The command is used to create the entity classes and the `DbContext` class for the database.

## Usage

Use the following command to scaffold the database in NuGet Package Manager Console.

``` powershell
Scaffold-DbContext -Connection "Data Source=[Host];Initial Catalog=[DbName];User ID=[Uid];Password=[Pwd];TrustServerCertificate=True" -Provider Microsoft.EntityFrameworkCore.SqlServer -Context AppDbContext -ContextDir Db -OutputDir Db/Models [-Tables <String[]>] -Force
```

**Note:** Replace the placeholders with the actual values.

After generating the `AppDbContext`, We need to **replaced** method `OnConfiguring` method to the `AppDbContext` class to configure the connection string.

``` csharp
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    if (!optionsBuilder.IsConfigured)
    {
        var builder = new ConfigurationBuilder()
            .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
            .AddJsonFile(Const.ConfigurationFile, optional: false, reloadOnChange: true);
        var config = builder.Build();
        var connectionString = config.GetConnectionString("Default");

        optionsBuilder.UseSqlServer(connectionString);
    }
}
```

_**Importal**_ Manual update `OnConfiguring` method is mandatory **each time** you scaffold the database. To keep connection string safe.

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