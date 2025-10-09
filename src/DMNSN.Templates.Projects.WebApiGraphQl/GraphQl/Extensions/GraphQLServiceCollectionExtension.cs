using DMNSN.Templates.Projects.WebApiGraphQl.Constraints;
using DMNSN.Templates.Projects.WebApiGraphQl.GraphQl.Types;
using DMNSN.Templates.Projects.WebApiGraphQl.Settings;

namespace DMNSN.Templates.Projects.WebApiGraphQl.GraphQl.Extensions;

/// <summary>
/// Extension methods for IServiceCollection to add GraphQL services.
/// </summary>
public static class GraphQlServiceCollectionExtension
{
    /// <summary>
    /// Extension method to add GraphQL services to the IServiceCollection.
    /// </summary>
    /// <param name="services">The services.</param>
    /// <param name="configure">The configure.</param>
    /// <returns></returns>
    public static IServiceCollection AddGraphQl(
        this IServiceCollection services,
        IConfiguration configure)
    {
        // Configure options
        var option = configure
            .GetSection(ConfigureKeyConst.GraphQl)
            .Get<GraphQlSettings>()
            ?? new GraphQlSettings();

        // Add GraphQL Services
        return services.AddGraphQl(option);
    }

    /// <summary>
    /// Extension method to add GraphQL services to the IServiceCollection.
    /// </summary>
    /// <param name="services">The services.</param>
    /// <param name="configure">The configure.</param>
    /// <returns></returns>
    public static IServiceCollection AddGraphQl(
        this IServiceCollection services,
        Action<GraphQlSettings> configure)
    {
        // Configure options
        var option = new GraphQlSettings();
        configure(option);

        // Add GraphQL Services
        return services.AddGraphQl(option);
    }

    /// <summary>
    /// Extension method to add GraphQL services to the IServiceCollection.
    /// </summary>
    /// <param name="services">The services.</param>
    /// <param name="option">The option.</param>
    /// <returns></returns>
    public static IServiceCollection AddGraphQl(
        this IServiceCollection services,
        GraphQlSettings option)
    {
        services
            .AddGraphQLServer(schemaName: option.Name)
            .AddQueryType<QueryType>()
            .AddMutationType<MutationType>()
            .AddType<UlidType>()
            .DisableIntrospection(option.DisableIntrospection);

        // Return the collection
        return services;
    }
}