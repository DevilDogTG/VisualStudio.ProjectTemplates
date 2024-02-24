using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using System.Reflection;
using Template.ConsoleMSSQL.Constraints;
using Template.ConsoleMSSQL.Models;
using Template.ConsoleMSSQL.Services;

var builder = Host.CreateApplicationBuilder(args);
builder.Configuration.SetBasePath(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location));
builder.Configuration.AddJsonFile(Const.ConfigurationFile, optional: false, reloadOnChange: true);
var config = builder.Configuration.GetSection(Const.ConfigurationKey).Get<ConfigurationModel>() ?? throw new ArgumentNullException("Configuration not found.");

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