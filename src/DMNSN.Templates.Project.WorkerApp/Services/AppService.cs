using DMNSN.Templates.Project.WorkerApp.Interfaces.Services;
using DMNSN.Templates.Project.WorkerApp.Settings;
using Microsoft.Extensions.Options;

namespace DMNSN.Templates.Project.WorkerApp.Services;

public class AppService(
    ILogger<AppService> _logger,
    IOptionsMonitor<AppSettings> _config) : IAppService, IDisposable
{
    private readonly ILogger<AppService> logger = _logger;
    private readonly IOptionsMonitor<AppSettings> config = _config;

    private readonly IDisposable? changeSubscription = _config.OnChange(
        (settings, name) =>
        {
            _logger.LogInformation("Configuration changed [{Name}]: {WorkerName} at {Timestamp}",
                name,
                settings.ServiceName,
                DateTime.Now);
        });

    public Task RunProcessAsync(CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var currentSettings = config.CurrentValue;
        logger.LogInformation("Running {Name}", nameof(AppService));
        logger.LogInformation("Service: {AppName}", currentSettings.ServiceName);
        // Example process logic
        if (logger.IsEnabled(LogLevel.Information))
        {
            logger.LogInformation("AppService running at: {Time}", DateTimeOffset.Now);
        }
        return Task.CompletedTask;
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