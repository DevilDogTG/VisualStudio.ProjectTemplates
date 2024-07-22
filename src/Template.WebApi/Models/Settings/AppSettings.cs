namespace Template.WebApi.Models.Settings
{
    public class AppSettings
    {
        public bool HttpsRedirect { get; set; } = true;
        public string CorrelationKey { get; set; } = "X-Correlation-ID";
        public AppLogSettings Logging { get; set; } = new AppLogSettings();
    }

    public class AppLogSettings
    {
        public long FileSize { get; set; } = 104857600;
        public int FlushInterval { get; set; } = 1;
        public LoggingSetting ConsoleLog { get; set; } = new LoggingSetting() { MinimumLevel = "Information" };
        public LoggingSetting AppLog { get; set; } = new LoggingSetting();
        public LoggingSetting AppJsonLog { get; set; } = new LoggingSetting();
        public LoggingSetting PerformanceLog { get; set; } = new LoggingSetting();
    }

    public class LoggingSetting
    {
        public bool Enable { get; set; } = true;
        public string MinimumLevel { get; set; } = "Debug";
        public string Path { get; set; } = "logs/logging..log";
        public string Template { get; set; } = "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}";
    }
}
