using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using System.Reflection;
using Template.Console.Constraints;
using Template.Console.Models;
using Template.Console.Services;

var builder = Host.CreateApplicationBuilder(args);
builder.Configuration.SetBasePath(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location));
builder.Configuration.AddJsonFile(Const.ConfigurationFile, optional: false, reloadOnChange: true);
var config = builder.Configuration.GetSection(Const.ConfigurationKey).Get<ConfigurationModel>();
if (config is null)
{ throw new ArgumentNullException("Configuration not found."); }

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