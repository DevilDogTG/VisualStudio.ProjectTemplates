using HotChocolate.Language;
using NUlid;

namespace DMNSN.Templates.Projects.WebApiGraphQl.GraphQl.Types;

/// <summary>
/// Implements the ULID scalar type for GraphQL.
/// </summary>
/// <seealso cref="ScalarType&lt;Ulid, StringValueNode&gt;" />
public sealed class UlidType : ScalarType<Ulid, StringValueNode>
{
    /// <summary>
    /// Initializes a new instance of the <see cref="UlidType"/> class.
    /// </summary>
    public UlidType() : base("ULID")
    {
        Description = "Universally Unique Lexicographically Sortable Identifier.";
    }

    // Tell HC which AST node we use
    /// <summary>
    /// Defines if the specified <paramref name="valueSyntax" />
    /// can be parsed by this scalar.
    /// </summary>
    /// <param name="valueSyntax">The literal that shall be checked.</param>
    /// <returns>
    /// <c>true</c> if the literal can be parsed by this scalar;
    /// otherwise, <c>false</c>.
    /// </returns>
    protected override bool IsInstanceOfType(StringValueNode valueSyntax) => TryParse(valueSyntax.Value, out _);

    /// <summary>
    /// Parses the specified <paramref name="valueSyntax" />
    /// to the .net representation of this type.
    /// </summary>
    /// <param name="valueSyntax">The literal that shall be parsed.</param>
    /// <returns></returns>
    /// <exception cref="SerializationException">Invalid ULID literal: '{valueSyntax.Value}'.</exception>
    protected override Ulid ParseLiteral(StringValueNode valueSyntax)
    {
        if (TryParse(valueSyntax.Value, out var ulid))
        {
            return ulid;
        }
        throw new SerializationException($"Invalid ULID literal: '{valueSyntax.Value}'.", this);
    }

    /// <summary>
    /// Parses a runtime value into a valueSyntax.
    /// </summary>
    /// <param name="runtimeValue">The value to parse</param>
    /// <returns>
    /// The parsed value syntax
    /// </returns>
    protected override StringValueNode ParseValue(Ulid runtimeValue)
        => new(runtimeValue.ToString());

    /// <summary>
    /// Parses a result value of this scalar into a GraphQL value syntax representation.
    /// </summary>
    /// <param name="resultValue">A result value representation of this type.</param>
    /// <returns>
    /// Returns a GraphQL value syntax representation of the <paramref name="resultValue" />.
    /// </returns>
    /// <exception cref="HotChocolate.Types.SerializationException">Cannot parse result value to ULID: {resultValue}</exception>
    public override IValueNode ParseResult(object? resultValue)
    {
        if (resultValue is null)
        {
            return NullValueNode.Default;
        }

        if (resultValue is Ulid u)
        {
            return new StringValueNode(u.ToString());
        }
        if (resultValue is string s && TryParse(s, out var parsed))
        {
            return new StringValueNode(parsed.ToString());
        }

        throw new SerializationException($"Cannot parse result value to ULID: {resultValue}", this);
    }

    /// <summary>
    /// Try to deserialize a result value of this scalar into a runtime representation.
    /// </summary>
    /// <param name="resultValue"></param>
    /// <param name="runtimeValue"></param>
    /// <returns></returns>
    /// <inheritdoc />
    public override bool TryDeserialize(object? resultValue, out object? runtimeValue)
    {
        if (resultValue is Ulid u)
        {
            runtimeValue = u;
            return true;
        }

        if (resultValue is string s && TryParse(s, out var parsed))
        {
            runtimeValue = parsed;
            return true;
        }

        runtimeValue = null;
        return resultValue is null;
    }

    /// <summary>
    /// Try to serialize a runtime value of this scalar into a result representation.
    /// </summary>
    /// <param name="runtimeValue"></param>
    /// <param name="resultValue"></param>
    /// <returns></returns>
    /// <inheritdoc />
    public override bool TrySerialize(object? runtimeValue, out object? resultValue)
    {
        if (runtimeValue is Ulid u)
        {
            resultValue = u.ToString();
            return true;
        }

        if (runtimeValue is string s && TryParse(s, out var parsed))
        {
            resultValue = parsed.ToString();
            return true;
        }

        resultValue = null;
        return runtimeValue is null;
    }

    /// <summary>
    /// Tries the parse.
    /// </summary>
    /// <param name="s">The s.</param>
    /// <param name="ulid">The ulid.</param>
    /// <returns></returns>
    private static bool TryParse(string s, out Ulid ulid)
    {
        try
        {
            ulid = Ulid.Parse(s);
            return true;
        }
        catch
        {
            ulid = default;
            return false;
        }
    }
}