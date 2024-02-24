namespace Template.WebApiMSSQL.Models
{
    public interface IConfigurationModel
    {
        public bool EnableSwagger { get; set; }
        public PerformanceLogConfig PerformanceLog { get; set; }
    }
}
