namespace DMNSN.Templates.Projects.WorkerApp.Settings;

/// <summary>
/// Application settings for the worker service.
/// </summary>
public class AppSettings
{
    public string ServiceName { get; set; } = "DMNSN Worker Service";
    public int WorkerInterval { get; set; } = 1000; // Interval in milliseconds for worker execution
}