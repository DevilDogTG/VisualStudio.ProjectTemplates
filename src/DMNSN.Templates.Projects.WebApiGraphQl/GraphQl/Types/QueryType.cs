using DMNSN.Templates.Projects.WebApiGraphQl.Interfaces;

namespace DMNSN.Templates.Projects.WebApiGraphQl.GraphQl.Types;

/// <summary>
/// Query type for GraphQL schema.
/// </summary>
/// <seealso cref="ObjectType" />
public partial class QueryType : ObjectType
{
    /// <summary>
    /// Override this to configure the type.
    /// </summary>
    /// <param name="descriptor">The descriptor allows to configure the interface type.</param>
    protected override void Configure(IObjectTypeDescriptor descriptor)
    {
        descriptor.Name("query");

        descriptor
            .Field("example")
            .Type<StringType>()
            .Argument("message", a => a.Type<StringType>().DefaultValue("World"))
            .Resolve(context => context
                .Service<IExampleService>()
                .GetExample(context.ArgumentValue<string>("message")));

        descriptor
            .Field("version")
            .Type<StringType>()
            .Resolve(context => context
                .Service<IExampleService>()
                .GetVersionInfo());

        descriptor
            .Field("correlationId")
            .Type<StringType>()
            .Resolve(context => context
                .Service<IExampleService>()
                .GetCorrelationId());
    }
}