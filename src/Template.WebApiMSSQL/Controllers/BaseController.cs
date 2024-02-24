using Microsoft.AspNetCore.Mvc;
using Template.WebApiMSSQL.Interfaces;

namespace Template.WebApiMSSQL.Controllers
{
    public class BaseController : Controller
    {
        private readonly IConfigurationModel config;
        public BaseController(IConfigurationModel _config) : base()
        {
            config = _config;
        }
    }
}
