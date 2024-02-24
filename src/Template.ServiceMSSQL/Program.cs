using Serilog;
using Template.ServiceMSSQL.Contraints;
using Template.ServiceMSSQL.Models;
using Template.ServiceMSSQL.Services;

var builder = Host.CreateApplicationBuilder(args);
var config = builder.Configuration.GetSection(Const.ConfigurationKey).Get<ConfigurationModel>() ?? throw new ArgumentNullException("Configuration not found.");

builder.Services.AddWindowsService();
builder.Services.AddSerilog(config =>
{
    config.ReadFrom.Configuration(builder.Configuration);
    config.Enrich.FromLogContext();
});
builder.Services.AddSingleton<IConfigurationModel, ConfigurationModel>(sp => config);
builder.Services.AddHostedService<WorkerService>();

var host = builder.Build();
await host.RunAsync();

