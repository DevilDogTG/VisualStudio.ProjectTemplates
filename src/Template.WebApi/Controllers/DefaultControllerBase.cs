using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Template.WebApi.Models.Settings;

namespace Template.WebApi.Controllers
{
    public class DefaultControllerBase : ControllerBase
    {
        protected readonly AppSettings config;
        protected readonly ILogger logger;

        public DefaultControllerBase(ILogger _logger, IOptions<AppSettings> _config)
        {
            config = _config.Value;
            logger = _logger;
        }
    }
}
