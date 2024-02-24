namespace Template.WebApi.Models
{
    public class ConfigurationModel : IConfigurationModel
    {
        public bool EnableSwagger { get; set; } = false;
        public PerformanceLogConfig PerformanceLog { get; set; } = new PerformanceLogConfig();
    }

    public class PerformanceLogConfig
    {
        public bool EnableLogging { get; set; } = true;
        public string Path { get; set; } = string.Empty;
        public string CorrelationKey { get; set; } = "X-Correlation-Id";
    }
}
