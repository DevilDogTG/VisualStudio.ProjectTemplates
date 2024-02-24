using Microsoft.AspNetCore.Mvc.Controllers;
using Newtonsoft.Json;
using System.Diagnostics;
using Template.WebApi.Models;

namespace Template.WebApi.Middlewares
{
    public class PerformanceLogMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<PerformanceLogMiddleware> logger;
        private readonly IConfigurationModel config;

        public PerformanceLogMiddleware(RequestDelegate next, ILogger<PerformanceLogMiddleware> _logger, IConfigurationModel _config)
        {
            _next = next;
            logger = _logger;
            config = _config;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            Stopwatch PerfTime = new Stopwatch();
            PerfTime.Start();
            var RqDateTime = DateTime.Now;
            // Do something before calling the next middleware
            // This is similar to OnActionExecuting in Action Filters

            await _next(context);

            // Do something after the next middleware has completed
            // This is similar to OnActionExecuted in Action Filters
            PerfTime.Stop();
            var actionDescriptor = context.GetEndpoint()?.Metadata.GetMetadata<ControllerActionDescriptor>();
            if (actionDescriptor != null && config.PerformanceLog.EnableLogging)
            {
                Stopwatch OthTime = new Stopwatch();
                OthTime.Start();
                var correlationId = context.Request.Headers[config.PerformanceLog.CorrelationKey];
                var controllerName = actionDescriptor.ControllerName; // Similar to context.Request.RouteValues["controller"]
                var actionName = actionDescriptor.ActionName; // Similar to context.Request.RouteValues["action"]
                if (false)
                {
                    // TODO: Handle performace logging each controller and action
                    OthTime.Stop();
                }
                else
                {
                    var perfDefault = new PerfDefaultModel
                    {
                        RqDateTime = RqDateTime,
                        RsDateTime = DateTime.Now,
                        ControllerName = controllerName,
                        ActionName = actionName,
                        CorrelationId = correlationId,
                        StatusCode = context.Response.StatusCode.ToString(),
                        ProcessTime = PerfTime.Elapsed.Milliseconds
                    };
                    OthTime.Stop();
                    perfDefault.OtherTime = OthTime.Elapsed.Milliseconds;
                    logger.LogInformation("{perf}", JsonConvert.SerializeObject(perfDefault));
                }
            }
        }
    }
}
