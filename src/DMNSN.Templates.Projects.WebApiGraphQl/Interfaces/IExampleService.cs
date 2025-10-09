namespace DMNSN.Templates.Projects.WebApiGraphQl.Interfaces;

public interface IExampleService
{
    string GetExample(string message);

    string GetVersionInfo();

    string GetCorrelationId();
}