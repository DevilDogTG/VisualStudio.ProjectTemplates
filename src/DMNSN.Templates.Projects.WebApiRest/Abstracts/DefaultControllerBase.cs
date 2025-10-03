using DMNSN.Templates.Projects.WebApiRest.Settings;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using System.Reflection;

namespace DMNSN.Templates.Projects.WebApiRest.Abstracts;

/// <summary>
/// A default base controller with common properties and methods.
/// </summary>
/// <seealso cref="Microsoft.AspNetCore.Mvc.ControllerBase" />
public abstract class DefaultControllerBase : ControllerBase
{
    protected readonly ILogger _logger;
    protected readonly IHttpContextAccessor _httpContextAccessor;
    protected readonly string correlationID;
    protected AppSettings _config;

    /// <summary>
    /// Initializes a new instance of the <see cref="DefaultControllerBase"/> class.
    /// </summary>
    /// <param name="logger">The logger.</param>
    /// <param name="httpContextAccessor">The HTTP context accessor.</param>
    /// <param name="config">The configuration.</param>
    protected DefaultControllerBase(
        ILogger logger,
        IHttpContextAccessor httpContextAccessor,
        IOptionsMonitor<AppSettings> config)
    {
        _logger = logger;
        _httpContextAccessor = httpContextAccessor;
        _config = config.CurrentValue;
        config.OnChange(newValues => _config = newValues);
        if (_httpContextAccessor.HttpContext != null)
        { correlationID = (string?)_httpContextAccessor.HttpContext.Request.Headers[_config.CorrelationKey] ?? ""; }
        else { correlationID = ""; }
    }

    /// <summary>
    /// Gets the raw request.
    /// </summary>
    /// <returns></returns>
    protected string GetRawRequest()
    {
        Request.Body.Position = 0;
        var bodyStream = new StreamReader(Request.Body);
        return bodyStream.ReadToEndAsync().Result;
    }

    /// <summary>
    /// Gets the application version.
    /// </summary>
    /// <returns></returns>
    protected static string? GetAppVersion()
    {
        string version;
        var appVersion = Assembly.GetExecutingAssembly().GetName().Version;
        if (appVersion != null)
        { version = $"{appVersion.Major}.{appVersion.Minor}.{appVersion.Build}"; }
        else
        {
            var versionAttribute = Assembly.GetExecutingAssembly()
                .GetCustomAttribute<AssemblyInformationalVersionAttribute>();
            version = versionAttribute?.InformationalVersion ?? "x.x.x";
        }
        return version;
    }
}