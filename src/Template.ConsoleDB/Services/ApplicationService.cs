using Microsoft.Extensions.Logging;

namespace Template.ConsoleMSSQL.Services
{
    public class ApplicationService
    {
        private readonly ILogger<ApplicationService> _logger;
        public ApplicationService(ILogger<ApplicationService> logger)
        {
            _logger = logger;
        }

        public void Run()
        {
            _logger.LogDebug("Debuging log start.");
            _logger.LogInformation("Application is running");
        }
    }
}
