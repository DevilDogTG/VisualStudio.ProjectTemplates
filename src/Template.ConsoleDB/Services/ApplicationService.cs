using Microsoft.Extensions.Logging;
using Template.ConsoleMSSQL.Models;

namespace Template.ConsoleMSSQL.Services
{
    public class ApplicationService
    {
        private readonly IConfigurationModel config;
        private readonly ILogger<ApplicationService> logger;
        public ApplicationService(ILogger<ApplicationService> _logger, IConfigurationModel _config)
        {
            logger = _logger;
            config = _config;
        }

        public void Run()
        {
            logger.LogInformation("Application is running");
        }
    }
}
