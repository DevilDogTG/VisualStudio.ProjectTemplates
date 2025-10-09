namespace DMNSN.Templates.Projects.WebApiGraphQl.Settings
{
    public class AppSettings
    {
        public string CorrelationKey { get; set; } = "X-Correlation-Id";
        public GraphQlSettings GraphQl { get; set; } = new GraphQlSettings();
    }
}