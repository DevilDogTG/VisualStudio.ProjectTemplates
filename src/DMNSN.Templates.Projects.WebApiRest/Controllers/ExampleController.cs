using DMNSN.Templates.Projects.WebApiRest.Abstracts;
using DMNSN.Templates.Projects.WebApiRest.Settings;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace DMNSN.Templates.Projects.WebApiRest.Controllers;

/// <summary>
/// Example controller for demonstration purposes.
/// </summary>
/// <seealso cref="DefaultControllerBase" />
[Route("api/example")]
public class ExampleController(
    ILogger<ExampleController> logger,
    IHttpContextAccessor httpContextAccessor,
    IOptionsMonitor<AppSettings> config) : DefaultControllerBase(logger, httpContextAccessor, config)
{
    /// <summary>
    /// Gets the example.
    /// </summary>
    /// <returns></returns>
    [HttpGet]
    public IActionResult GetExample()
    {
        _logger.LogInformation("Example action called. Correlation ID: {CorrelationID}", correlationID);
        var response = new
        {
            Message = "This is an example response.",
            CorrelationID = correlationID,
            AppVersion = GetAppVersion()
        };
        return Ok(response);
    }

    /// <summary>
    /// Posts the echo.
    /// </summary>
    /// <returns></returns>
    [HttpPost("echo")]
    public IActionResult PostEcho()
    {
        var rawRequest = GetRawRequest();
        _logger.LogInformation("Echo action called. Correlation ID: {CorrelationID}. Raw Request: {RawRequest}", correlationID, rawRequest);
        var response = new
        {
            Message = "Echoing back your request.",
            CorrelationID = correlationID,
            RawRequest = rawRequest,
            AppVersion = GetAppVersion()
        };
        return Ok(response);
    }

    /// <summary>
    /// Gets the version.
    /// </summary>
    /// <returns></returns>
    [HttpGet("version")]
    public IActionResult GetVersion()
    {
        var version = GetAppVersion();
        _logger.LogInformation("Version action called. Correlation ID: {CorrelationID}. App Version: {AppVersion}", correlationID, version);
        var response = new
        {
            Message = "Application version retrieved.",
            CorrelationID = correlationID,
            AppVersion = version
        };
        return Ok(response);
    }
}