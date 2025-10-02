namespace DMNSN.Templates.Project.WebApiRest.Settings;

public class LogSettings
{
    public long FileSize { get; set; } = 104857600;
    public int FlushInterval { get; set; } = 1;
    public LogSetting ConsoleLog { get; set; } = new() { MinimumLevel = "Information" };
    public LogSetting AppLog { get; set; } = new();
}

public class LogSetting
{
    public bool Enable { get; set; } = true;
    public string MinimumLevel { get; set; } = "Information";
    public string Path { get; set; } = "logs/apps..log";
    public string Template { get; set; } = "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}";
}