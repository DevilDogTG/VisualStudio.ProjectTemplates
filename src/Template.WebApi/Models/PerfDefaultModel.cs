namespace Template.WebApi.Models
{
    public class PerfDefaultModel
    {
        public DateTime RqDateTime { get; set; } = DateTime.Now;
        public DateTime RsDateTime { get; set; } = DateTime.Now;
        public string ControllerName { get; set; } = string.Empty;
        public string ActionName { get; set; } = string.Empty;
        public string CorrelationId { get; set; } = string.Empty;
        public string StatusCode { get; set; } = string.Empty;
        public int ProcessTime { get; set; } = 0;
        public int OtherTime { get; set; } = 0;
        public int ResponseTime { get { return ProcessTime + OtherTime; } }
    }
}
