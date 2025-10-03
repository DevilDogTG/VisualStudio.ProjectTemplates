using DMNSN.AspNetCore.Middlewares.CorrelationId;
using DMNSN.Templates.Projects.WebApiRest.Constraints;
using DMNSN.Templates.Projects.WebApiRest.Settings;
using Microsoft.AspNetCore.HttpOverrides;
using Serilog;
using Serilog.Events;

var builder = WebApplication.CreateBuilder(args);

// Validate the container and scopes early (catches many mistakes at build time)
builder.Host.UseDefaultServiceProvider((ctx, opts) =>
{
    opts.ValidateOnBuild = true;
    opts.ValidateScopes = ctx.HostingEnvironment.IsDevelopment();
});

// Configuration sources
builder.Configuration
    .AddJsonFile(
        path: ConfigureFileConst.Application,
        optional: false,
        reloadOnChange: true)
    .AddJsonFile(
        path: ConfigureFileConst.Logging,
        optional: true,
        reloadOnChange: false);

var appSection = builder.Configuration.GetSection(ConfigureKeyConst.Application);
var logSection = builder.Configuration.GetSection(ConfigureKeyConst.Logging);

// Prefer Options + validation over manual Get<T>() + throw
builder.Services
    .AddOptions<AppSettings>()
    .Bind(appSection)
    .ValidateDataAnnotations()
    .Validate(o => o is not null, "AppSettings section is missing.")
    .ValidateOnStart();

builder.Services
    .AddOptions<LogSettings>()
    .Bind(logSection)
    .ValidateDataAnnotations()
    .Validate(o => o is not null, "Logging configuration section is missing.")
    .ValidateOnStart();

var appConfig = appSection.Get<AppSettings>()
    ?? throw new InvalidOperationException("AppSettings section is missing.");

var logConfig = logSection.Get<LogSettings>()
    ?? throw new InvalidOperationException("Logging configuration section is missing.");

builder.Host.UseSerilog((context, configuration) =>
{
    configuration
        .ReadFrom.Configuration(context.Configuration)
            .Enrich.WithMachineName()
            .Enrich.WithHeaderCorrelationId(keyName: appConfig.CorrelationKey);
    if (logConfig.ConsoleLog.Enable)
    {
        configuration.WriteTo.Console(
            restrictedToMinimumLevel: LogEventLevel.Information,
            outputTemplate: logConfig.ConsoleLog.Template);
    }
    if (logConfig.AppLog.Enable)
    {
        configuration.WriteTo.File(logConfig.AppLog.Path,
            fileSizeLimitBytes: logConfig.FileSize,
            flushToDiskInterval: TimeSpan.FromSeconds(logConfig.FlushInterval),
            rollingInterval: RollingInterval.Day,
            rollOnFileSizeLimit: true,
            outputTemplate: logConfig.AppLog.Template);
    }
});

// Register services
builder.Services.AddControllers();
builder.Services.AddHttpContextAccessor();
builder.Services.AddEndpointsApiExplorer();

// Custom register

// Register Configuration
builder.Services
    .Configure<AppSettings>(appSection)
    .Configure<LogSettings>(logSection)
    .Configure<ForwardedHeadersOptions>(options =>
        options.ForwardedHeaders =
            ForwardedHeaders.XForwardedFor
            | ForwardedHeaders.XForwardedProto);

var app = builder.Build();

// Register middleware
app.UseCorrelationIdMiddleware(options =>
    options.CorrelationKey = appConfig.CorrelationKey);

// HTTP Pipeline
app.UseForwardedHeaders();
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

await app.RunAsync();