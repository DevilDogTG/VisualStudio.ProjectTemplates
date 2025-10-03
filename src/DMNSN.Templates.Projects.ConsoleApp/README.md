## DMNSN.Templates.Projects.ConsoleApp code style

`DMNSN.Templates.Projects.ConsoleApp` is the reference implementation for these templates. The project adopts a concise C# layout with the following characteristics:

- **Top-level statements** in `Program.cs` configure the host and Serilog
  without an explicit `Main` method.
- **File-scoped namespaces** and C# *primary constructors* keep service
  definitions compact while supporting dependency injection.
- Command line options are parsed with **CommandLineParser** using `[Verb]`
  and `[Option]` attributes.
- Configuration values are bound to strongly typed classes via
  `IOptionsMonitor<T>` and support live reload with change notifications.
- Services that watch for configuration changes implement `IDisposable` to
  clean up subscriptions.
- An `.editorconfig` file suppresses `CS8604` warnings to reduce nullability
  noise during development.

