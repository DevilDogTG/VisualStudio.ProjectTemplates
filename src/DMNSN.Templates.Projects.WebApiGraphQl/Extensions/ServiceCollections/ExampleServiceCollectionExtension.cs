using DMNSN.Templates.Projects.WebApiGraphQl.Interfaces;
using DMNSN.Templates.Projects.WebApiGraphQl.Services;

namespace DMNSN.Templates.Projects.WebApiGraphQl.Extensions.ServiceCollections;

/// <summary>
///
/// </summary>
public static class ExampleServiceCollectionExtension
{
    /// <summary>
    /// Adds the example service.
    /// </summary>
    /// <param name="services">The services.</param>
    /// <returns></returns>
    public static IServiceCollection AddExampleService(
        this IServiceCollection services)
    {
        services.AddTransient<IExampleService, ExampleService>();
        return services;
    }
}