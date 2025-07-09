using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using System.Reflection;
using Template.Console.Constraints;
using Template.Console.Models;
using Template.Console.Services;
using Template.Console.Settings;

var basePath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? throw new ArgumentException("Cannot set basePath.");
var builder = Host.CreateApplicationBuilder(args);
builder.Configuration
    .SetBasePath(basePath)
    .AddJsonFile(ConfigFiles.Application, optional: false, reloadOnChange: true)
    .AddJsonFile(ConfigFiles.Logging, optional: true, reloadOnChange: false);
var config = builder.Configuration
    .GetSection(ConfigKeys.Application)
    .Get<AppSettings>() ?? throw new ArgumentException("Cannot load config");
var configLogging = builder.Configuration
    .GetSection(ConfigKeys.Logging)
    .Get<LoggingSettings>() ?? throw new Exception("Configuration not found.");

builder.Services.AddSerilog(config =>
{
    config.ReadFrom.Configuration(builder.Configuration);
    config.Enrich.FromLogContext();
});
builder.Services.AddSingleton<IConfigurationModel, ConfigurationModel>(sp => config);
builder.Services.AddTransient<ApplicationService>();

var host = builder.Build();
var app = host.Services.GetRequiredService<ApplicationService>();
app.Run();