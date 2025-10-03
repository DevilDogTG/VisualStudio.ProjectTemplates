using DMNSN.Templates.Projects.ConsoleApp.Interfaces.Services;
using DMNSN.Templates.Projects.ConsoleApp.Settings;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;

namespace DMNSN.Templates.Projects.ConsoleApp.Services;

public class ExampleService(
    ILogger<AppService> logger,
    IOptionsMonitor<AppSettings> config) : IExampleService, IDisposable
{
    private readonly ILogger<AppService> logger = logger;
    private readonly IOptionsMonitor<AppSettings> config = config;

    private readonly IDisposable? changeSubscription = config.OnChange(
        (settings, name) =>
        {
            logger.LogInformation("Configuration changed: {AppName}", settings.ApplicationName);
        });

    public int Run(ExampleArgs args)
    {
        var currentSettings = config.CurrentValue;
        logger.LogInformation("Running {Name}", nameof(ExampleService));
        logger.LogInformation("Application Name: {AppName}", currentSettings.ApplicationName);
        logger.LogInformation("Args: {Args}", JsonConvert.SerializeObject(args));
        return 0;
    }

    public void Dispose()
    {
        Dispose(disposing: true);
        GC.SuppressFinalize(this);
    }

    protected virtual void Dispose(bool disposing)
    {
        if (disposing)
        {
            changeSubscription?.Dispose();
        }
    }
}