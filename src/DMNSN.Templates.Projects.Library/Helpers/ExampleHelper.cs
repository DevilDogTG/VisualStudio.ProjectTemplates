using Microsoft.Extensions.Logging;

namespace DMNSN.Templates.Projects.Library.Helpers;

public static class ExampleHelper
{
    public static string GetExample(string message, ILogger? logger)
    {
        logger?.LogInformation("GetExample called with message: {Message}", message);
        return $"This is an example helper method. Input message is {message}";
    }
}