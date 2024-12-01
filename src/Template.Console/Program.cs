using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using Serilog.Events;
using System.Reflection;
using Template.Console.Constraints;
using Template.Console.Services;
using Template.Console.Settings;

var basePath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? throw new ArgumentException("Cannot set basePath.");
var builder = Host.CreateApplicationBuilder(args);
builder.Configuration.SetBasePath(basePath);
builder.Configuration
    .AddJsonFile(Const.ConfigurationFile, optional: false, reloadOnChange: true)
    .AddJsonFile(Const.LoggingConfigurationFile, optional: true, reloadOnChange: false);
var config = builder.Configuration.GetSection(ConfigKey.Application).Get<AppSettings>() ?? throw new ArgumentException("Configuration not found");
var configLog = builder.Configuration.GetSection(ConfigKey.Logging).Get<LoggingSettings>() ?? throw new ArgumentException("Logging configuration not found");

builder.Services.AddSerilog(config =>
{
    config.ReadFrom.Configuration(builder.Configuration);
    config.Enrich.FromLogContext();
});

builder.Services.AddSerilog(loggerConfiguration =>
{
    loggerConfiguration
        .ReadFrom.Configuration(builder.Configuration)
            .Enrich.WithMachineName();
    if (configLog.ConsoleLog.Enable)
    {
        loggerConfiguration.WriteTo.Console(
            restrictedToMinimumLevel: LogEventLevel.Information,
            outputTemplate: configLog.ConsoleLog.Template);
    }
    if (configLog.FileLog.Enable)
    {
        loggerConfiguration.WriteTo.File(configLog.FileLog.Path,
            fileSizeLimitBytes: configLog.FileSize,
            flushToDiskInterval: TimeSpan.FromSeconds(configLog.FlushInterval),
            rollingInterval: RollingInterval.Day,
            rollOnFileSizeLimit: true,
            outputTemplate: configLog.FileLog.Template);
    }
});

// Register Configuration
builder.Services.Configure<AppSettings>(builder.Configuration.GetSection(ConfigKey.Application));
builder.Services.Configure<LoggingSettings>(builder.Configuration.GetSection(ConfigKey.Logging));
builder.Services.AddTransient<ApplicationService>();

var host = builder.Build();
var app = host.Services.GetRequiredService<ApplicationService>();
app.Run();