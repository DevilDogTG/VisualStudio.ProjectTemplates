namespace DMNSN.Templates.Projects.WebApiGraphQl.GraphQl.Types;

/// <summary>
/// Mutation type for GraphQL schema.
/// </summary>
/// <seealso cref="HotChocolate.Types.ObjectType" />
public partial class MutationType : ObjectType
{
    /// <summary>
    /// Override this to configure the type.
    /// </summary>
    /// <param name="descriptor">The descriptor allows to configure the interface type.</param>
    protected override void Configure(IObjectTypeDescriptor descriptor)
    {
        descriptor.Name("mutation");
        descriptor
            .Field("exampleMutation")
            .Type<StringType>()
            .Resolve(context => "This is example mutation endpoint.");
    }
}