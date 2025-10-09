using Microsoft.Extensions.Logging;

namespace DMNSN.Templates.Projects.Library;

/// <summary>
/// This is an example class in the library project.
/// </summary>
public class Example(
    ILogger<Example> logger)
{
    /// <summary>
    /// Gets the message.
    /// </summary>
    /// <returns></returns>
    public string GetMessage(string name)
    {
        logger.LogInformation("GetMessage called with name: {Name}", name);
        return $"Hello {name}, this is message from DMNSN.Templates.Projects.Library!";
    }
}