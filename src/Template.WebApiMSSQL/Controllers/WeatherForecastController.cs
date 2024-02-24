using Microsoft.AspNetCore.Mvc;
using Template.WebApiMSSQL.Models;

namespace Template.WebApiMSSQL.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherForecastController : DefaultControllerBase
    {
        private static readonly string[] Summaries = new[]
        {
            "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
        };

        public WeatherForecastController(ILogger<WeatherForecastController> _logger, IConfigurationModel _config) : base(_logger, _config)
        {
        }

        [HttpGet]
        public IEnumerable<WeatherForecast> Get()
        {
            try
            {
                logger.LogInformation("Logging with double qoute \"here\"");
                throw new Exception("Error in WeatherForecastController");
            } catch (Exception ex)
            {
                logger.LogError(ex, "Error in WeatherForecastController");
            }
            
            return Enumerable.Range(1, 5).Select(index => new WeatherForecast
            {
                Date = DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                TemperatureC = Random.Shared.Next(-20, 55),
                Summary = Summaries[Random.Shared.Next(Summaries.Length)]
            })
            .ToArray();
        }
    }
}
