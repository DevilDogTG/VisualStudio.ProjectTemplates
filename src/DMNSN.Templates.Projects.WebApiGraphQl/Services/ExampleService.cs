using DMNSN.Templates.Projects.WebApiGraphQl.Abstracts;
using DMNSN.Templates.Projects.WebApiGraphQl.Interfaces;
using DMNSN.Templates.Projects.WebApiGraphQl.Settings;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;

namespace DMNSN.Templates.Projects.WebApiGraphQl.Services;

/// <summary>
/// Example service class.
/// </summary>
public class ExampleService : BaseWebService, IExampleService
{
    private readonly ILogger<ExampleService> _logger;
    private AppSettings _options;

    public ExampleService(
        IHttpContextAccessor httpAccessor,
        ILogger<ExampleService> logger,
        IOptionsMonitor<AppSettings> options) : base(httpAccessor, options.CurrentValue)
    {
        _logger = logger;
        _options = options.CurrentValue;
        options.OnChange(opt =>
        {
            _logger.LogInformation("ExampleService options changed: {Options}", opt);
            _options = opt;
        });
    }

    /// <summary>
    /// Gets the example message.
    /// </summary>
    /// <param name="message">The message.</param>
    /// <returns></returns>
    public string GetExample(string message)
    {
        _logger.LogInformation("GetExample called with message: {Message}", message);
        _logger.LogDebug("AppSettings: {@AppSettings}", JsonConvert.SerializeObject(_options));
        return $"This is an example service message: {message}";
    }

    public string GetVersionInfo()
    {
        var version = GetVersion();
        _logger.LogInformation("GetVersion called: {Version}", version);
        return version ?? "";
    }

    public string GetCorrelationId()
    {
        _logger.LogInformation("Correlation ID is: {CorrelationId}", _correlationID);
        return _correlationID;
    }
}