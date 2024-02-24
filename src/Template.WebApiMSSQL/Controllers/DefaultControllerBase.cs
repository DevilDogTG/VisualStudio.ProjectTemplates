using Microsoft.AspNetCore.Mvc;
using Template.WebApiMSSQL.Models;

namespace Template.WebApiMSSQL.Controllers
{
    public class DefaultControllerBase : ControllerBase
    {
        protected readonly IConfigurationModel config;
        protected readonly ILogger logger;

        public DefaultControllerBase(ILogger _logger, IConfigurationModel _config)
        {
            config = _config;
            logger = _logger;
        }
    }
}
