using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Template.Console.Settings;

namespace Template.Console.Services
{
    public class ApplicationService
    {
        private AppSettings config;
        private readonly ILogger<ApplicationService> logger;
        public ApplicationService(ILogger<ApplicationService> _logger, IOptionsMonitor<AppSettings> _config)
        {
            logger = _logger;
            config = _config.CurrentValue;
            _config.OnChange(newValues => config = newValues);
        }

        public void Run()
        {
            logger.LogInformation("Application is running");
        }
    }
}
