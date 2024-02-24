namespace Template.ServiceMSSQL.Services
{
    public class WorkerService : BackgroundService
    {
        private readonly ILogger<WorkerService> logger;

        public WorkerService(ILogger<WorkerService> _logger)
        {
            logger = _logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                if (logger.IsEnabled(LogLevel.Information))
                {
                    logger.LogInformation("Worker running at: {time}", DateTimeOffset.Now);
                }
                await Task.Delay(1000, stoppingToken);
            }
        }
    }
}
