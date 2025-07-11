using CommandLine;
using CommandLine.Text;
using Microsoft.Extensions.Logging;
using System.Reflection;

namespace DMNSN.ConsoleApps.Services;

public class StartApplication(
    ILogger<StartApplication> _logger,
    AppService appService,
    ExampleService exampleService)
{
    private readonly ILogger<StartApplication> logger = _logger;
    private readonly Version version = Assembly
        .GetExecutingAssembly()
        .GetName()
        .Version
        ?? new Version(0, 0, 0);

    public void Start(string[] args)
    {
        logger.LogInformation("Main Application is starting [v{Version}]", version);
        var parser = new Parser(p =>
        {
            p.AutoVersion = false;
            p.CaseInsensitiveEnumValues = true;
        });
        var parserResult = parser.ParseArguments<AppArgs, ExampleArgs>(args);
        var rs = parserResult.MapResult(
            (AppArgs opts) => appService.Run(opts),
            (ExampleArgs opts) => exampleService.Run(opts),
            errors => DisplayHelp(parserResult, errors));
        logger.LogInformation("Main Application has finished running with {Result}", rs);
    }

    private static int DisplayHelp<T>(ParserResult<T> result, IEnumerable<Error> errs)
    {
        var helpText = HelpText.AutoBuild(result, h =>
        {
            h.AdditionalNewLineAfterOption = false;
            h.AddEnumValuesToHelpText = true;
            h.AutoVersion = false;
            return h;
        });
        Console.WriteLine(helpText);
        if (errs.IsHelp())
        { return 0; }
        throw new InvalidOperationException("No specified action.");
    }
}


