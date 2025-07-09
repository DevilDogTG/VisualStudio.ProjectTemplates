namespace Template.Console.Settings;

/// <summary>
/// Represents the configuration settings for logging in the application.
/// </summary>
/// <remarks>This class provides settings for various logging outputs, including file size limits,  flush
/// intervals, and specific configurations for console, application, JSON, and performance logs.</remarks>
public class LoggingSettings
{
    public long FileSize { get; set; } = 104857600;
    public int FlushInterval { get; set; } = 1;
    public LoggingSetting ConsoleLog { get; set; } = new LoggingSetting() { Enable = false, MinimumLevel = "Information" };
    public LoggingSetting AppLog { get; set; } = new LoggingSetting();
    public LoggingSetting AppJsonLog { get; set; } = new LoggingSetting();
    public LoggingSetting PerformanceLog { get; set; } = new LoggingSetting();
}

/// <summary>
/// Represents the configuration settings for logging in an application.
/// </summary>
/// <remarks>This class provides options to enable or disable logging, set the minimum log level,  specify the log
/// file path, and define the log message template. These settings are  typically used to configure logging behavior in
/// an application.</remarks>
public class LoggingSetting
{
    public bool Enable { get; set; } = true;
    public string MinimumLevel { get; set; } = "Debug";
    public string Path { get; set; } = "logs/logging..log";
    public string Template { get; set; } = "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}";
}