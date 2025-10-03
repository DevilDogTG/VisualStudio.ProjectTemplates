using DMNSN.Templates.Projects.WorkerApp.Interfaces.Services;

namespace DMNSN.Templates.Projects.WorkerApp.Services;

public class WorkerService(
    ILogger<WorkerService> _logger,
    IServiceScopeFactory _scopeFactory) : BackgroundService
{
    private readonly ILogger<WorkerService> logger = _logger;
    private readonly IServiceScopeFactory scopeFactory = _scopeFactory;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("WorkerService started at: {Time}", DateTimeOffset.Now);
        try
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using var scope = scopeFactory.CreateScope();
                    var appService = scope.ServiceProvider.GetRequiredService<IAppService>();
                    await appService.RunProcessAsync(stoppingToken);
                }
                catch (OperationCanceledException oe) when (stoppingToken.IsCancellationRequested)
                {
                    // Graceful shutdown, do not log as error
                    logger.LogInformation(oe, "WorkerService is stopping due to cancellation at: {Time} [{Message}]",
                        DateTimeOffset.Now,
                        oe.Message);
                    break;
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "Unhandled exception occurred in WorkerService loop at {Time}", DateTimeOffset.Now);
                }
                await Task.Delay(1000, stoppingToken);
            }
        }
        finally
        {
            logger.LogInformation("WorkerService stopped at: {Time}", DateTimeOffset.Now);
        }
    }
}