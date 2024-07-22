using Serilog;
using Serilog.Events;
using Serilog.Formatting.Compact;
using Template.WebApi.Constraints;
using Template.WebApi.Middlewares;
using Template.WebApi.Models.Settings;

var builder = WebApplication.CreateBuilder(args);
builder.Configuration
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile("serilogsettings.json", optional: true, reloadOnChange: false);
var config = builder.Configuration
    .GetSection(Const.ConfigurationKey)
    .Get<AppSettings>() ?? throw new ArgumentNullException("Configuration not found.");
builder.Host.UseSerilog((context, loggerConfiguration) =>
{
    loggerConfiguration
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.WithMachineName()
        .Enrich.WithHeaderCorrelationId(keyName: config.CorrelationKey);
    if (config.Logging.ConsoleLog.Enable)
    {
        loggerConfiguration.WriteTo.Console(
            restrictedToMinimumLevel: LogEventLevel.Information,
            outputTemplate: config.Logging.ConsoleLog.Template);
    }
    if (config.Logging.AppLog.Enable)
    {
        loggerConfiguration.WriteTo.File(config.Logging.AppLog.Path,
            fileSizeLimitBytes: config.Logging.FileSize,
            flushToDiskInterval: TimeSpan.FromSeconds(config.Logging.FlushInterval),
            rollingInterval: RollingInterval.Day,
            rollOnFileSizeLimit: true,
            outputTemplate: config.Logging.AppLog.Template);
    }
    if (config.Logging.AppJsonLog.Enable)
    {
        loggerConfiguration.WriteTo.File(
            formatter: new CompactJsonFormatter(),
            path: config.Logging.AppJsonLog.Path,
            fileSizeLimitBytes: config.Logging.FileSize,
            flushToDiskInterval: TimeSpan.FromSeconds(config.Logging.FlushInterval),
            rollingInterval: RollingInterval.Day,
            rollOnFileSizeLimit: true);
    }
});
builder.Services.Configure<AppSettings>(builder.Configuration.GetSection(Const.ConfigurationKey));
builder.Services.Configure<HotSettings>(builder.Configuration.GetSection(Const.DynamicConfigKey));
builder.Services.AddControllers();
builder.Services.AddHttpContextAccessor();
builder.Services.AddEndpointsApiExplorer();

//Configure Performance Logging
var perfLog = new LoggerConfiguration()
    .WriteTo.File(config.Logging.PerformanceLog.Path,
        fileSizeLimitBytes: config.Logging.FileSize,
        flushToDiskInterval: TimeSpan.FromSeconds(config.Logging.FlushInterval),
        rollingInterval: RollingInterval.Day,
        rollOnFileSizeLimit: true,
        outputTemplate: config.Logging.PerformanceLog.Template)
    .CreateLogger();
var loggerFactory = LoggerFactory.Create(builder => builder.AddSerilog(perfLog));
// Binding the logger to the DI container
var perfLogger = loggerFactory.CreateLogger<PerformanceLogMiddleware>();
builder.Services.AddSingleton(perfLogger);

//Configure Services
//builder.Services.AddSingleton<IConfigurationModel, ConfigurationModel>(sp => config);

var app = builder.Build();
app.UseMiddleware<PerformanceLogMiddleware>();

//Configure the HTTP request pipeline.
if (config.HttpsRedirect)
{
    app.UseHttpsRedirection();
}
app.UseAuthorization();
app.MapControllers();
app.Run();
