using Microsoft.Extensions.Logging;
using System.Security.Cryptography;
using System.Text;

namespace Template.Console.Services
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
