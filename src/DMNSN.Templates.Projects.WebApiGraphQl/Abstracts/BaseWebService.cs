using DMNSN.Templates.Projects.WebApiGraphQl.Settings;
using System.Reflection;

namespace DMNSN.Templates.Projects.WebApiGraphQl.Abstracts;

/// <summary>
/// Base class for web services (GraphQL).
/// </summary>
public abstract class BaseWebService
{
    protected readonly string _correlationID;

    /// <summary>
    /// Initializes a new instance of the <see cref="BaseWebService" /> class.
    /// </summary>
    /// <param name="httpAccessor">The HTTP accessor.</param>
    /// <param name="config">The configuration.</param>
    protected BaseWebService(
        IHttpContextAccessor httpAccessor,
        AppSettings config)
    {
        _correlationID = (string?)httpAccessor.HttpContext?.Request.Headers[config.CorrelationKey] ?? "";
    }

    /// <summary>
    /// Gets the version.
    /// </summary>
    /// <returns></returns>
    protected static string? GetVersion()
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