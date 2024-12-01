using CommandLine;

namespace Template.Console
{
    [Verb("run", isDefault: true, HelpText = "Show help information.")]
    public class Options
    {
        [Option('t', "test",
            Required = false,
            HelpText = "Test run")]
        public bool IsTest { get; set; }
    }
}
