using DMNSN.ConsoleApps.Interfaces.Services;
using DMNSN.ConsoleApps.Settings;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;

namespace DMNSN.ConsoleApps.Services;

public class AppService(
    ILogger<AppService> logger,
    IOptionsMonitor<AppSettings> config) : IAppService, IDisposable
{
    private readonly ILogger<AppService> logger = logger;
    private readonly IOptionsMonitor<AppSettings> config = config;
    private readonly IDisposable? changeSubscription = config.OnChange(
        (settings, name) =>
        {
            logger.LogInformation("Configuration changed: {AppName}", settings.ApplicationName);
        });

    public int Run(AppArgs args)
    {
        var currentSettings = config.CurrentValue;
        logger.LogInformation("Running {Name}", nameof(AppService));
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



