using DMNSN.Core.Constraints;
using DMNSN.Core.Settings;
using DMNSN.Templates.Projects.WorkerApp.Interfaces.Services;
using DMNSN.Templates.Projects.WorkerApp.Services;
using Serilog;

var builder = Host.CreateApplicationBuilder(args);
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
        ?? throw new InvalidOperationException("LoggingSettings configuration not found.");

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
builder.Services.AddWindowsService();
builder.Services.AddSystemd();
builder.Services.AddTransient<IAppService, AppService>();
builder.Services.AddHostedService<WorkerService>();

var host = builder.Build();
await host.RunAsync();