using CommandLine;

namespace DMNSN.ConsoleApps;

[Verb("run", isDefault: true, HelpText = "Run the application with the specified options.")]
public class AppArgs
{
    [Option('n', "no-commit",
        Default = false,
        HelpText = "Use when need to dry run, not commit change")]
    public bool NoCommit { get; set; } = false;
}

[Verb("example", HelpText = "Run the example application.")]
public class ExampleArgs
{
    [Option('e', "example-option",
        Required = false,
        Default = "default-value",
        HelpText = "An example option for demonstration purposes.")]
    public string ExampleOption { get; set; } = "default-value";
}
