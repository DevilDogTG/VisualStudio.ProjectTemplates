namespace DMNSN.Templates.Project.ConsoleApp.Settings;

/// <summary>
/// Represents the application settings configuration.
/// </summary>
/// <remarks>This class is used to store and manage configuration settings for the application.</remarks>
public class AppSettings
{
    public string ApplicationName { get; set; } = "DMNSN Application";
    public bool EnableDemo { get; set; } = false;
}
