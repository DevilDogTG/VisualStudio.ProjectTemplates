using $safeprojectname$.Services;
using DMNSN.Core.Constraints;
using DMNSN.Core.Settings;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using System.Configuration;
using System.Reflection;

var builder = Host.CreateApplicationBuilder(args);
var basePath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location)
               ?? throw new InvalidOperationException("Cannot define `basePath`");
builder.Configuration.SetBasePath(basePath);
builder.Configuration.AddJsonFile(
    path: ConfigureFile.Application,
    optional: false,
    reloadOnChange: true);
builder.Configuration.AddJsonFile(
    path: ConfigureFile.Logging,
    optional: false,
    reloadOnChange: false);

var loggingSettings = builder.Configuration
    .GetSection(ConfigureKey.Logging)
    .Get<LoggingSettings>()
        ?? throw new ConfigurationErrorsException("LoggingSettings configuration not found.");


builder.Services.AddSerilog(logger =>
{
    logger
        .ReadFrom.Configuration(builder.Configuration)
            .Enrich.WithMachineName();
    if (loggingSettings.ConsoleLog.Enable)
    {
        logger.WriteTo.Console(
            outputTemplate: loggingSettings.ConsoleLog.Template);
    }
    if (loggingSettings.FileLog.Enable)
    {
        logger.WriteTo.File(
            loggingSettings.FileLog.Path,
            fileSizeLimitBytes: loggingSettings.FileSize,
            flushToDiskInterval: TimeSpan.FromSeconds(loggingSettings.FlushInterval),
            rollingInterval: RollingInterval.Day,
            rollOnFileSizeLimit: true,
            outputTemplate: loggingSettings.ConsoleLog.Template);
    }
});
builder.Services.AddTransient<AppService>();
builder.Services.AddTransient<ExampleService>();
builder.Services.AddTransient<StartApplication>();

var host = builder.Build();
var app = host.Services.GetRequiredService<StartApplication>();
try
{
    app.Start(args);
    Environment.Exit(0);
}
catch (Exception ex)
{
    Console.WriteLine($"Exception: {ex.Message}");
    Environment.Exit(-1);
}


