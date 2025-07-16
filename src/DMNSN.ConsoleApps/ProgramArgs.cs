using CommandLine;

namespace DMNSN.ConsoleApps;

/// <summary>
/// Represents the command-line arguments for running the application.
/// </summary>
/// <remarks>This class is used to parse and store options provided to the application when executed with the
/// "run" verb. It includes options for controlling the application's behavior, such as whether to perform a dry
/// run.</remarks>
[Verb("run", isDefault: true, HelpText = "Run the application with the specified options.")]
public class AppArgs
{
    [Option('n', "no-commit",
        Default = false,
        HelpText = "Use when need to dry run, not commit change")]
    public bool NoCommit { get; set; } = false;
}

/// <summary>
/// Represents the command-line arguments for running the example application.
/// </summary>
/// <remarks>This class is used to parse and store the options provided to the example application via the command
/// line. It includes options that can be specified by the user to modify the application's behavior.</remarks>
[Verb("example", HelpText = "Run the example application.")]
public class ExampleArgs
{
    [Option('e', "example-option",
        Required = false,
        Default = "default-value",
        HelpText = "An example option for demonstration purposes.")]
    public string ExampleOption { get; set; } = "default-value";
}
