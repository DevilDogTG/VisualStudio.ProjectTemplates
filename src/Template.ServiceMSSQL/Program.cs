using Serilog;
using Template.ServiceMSSQL.Contraints;
using Template.ServiceMSSQL.Models;
using Template.ServiceMSSQL.Services;

var configuration = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json")
    .Build();
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(configuration)
    .Enrich.FromLogContext()
    .CreateLogger();

