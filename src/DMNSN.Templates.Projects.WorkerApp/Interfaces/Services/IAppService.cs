namespace DMNSN.Templates.Projects.WorkerApp.Interfaces.Services;

public interface IAppService
{
    Task RunProcessAsync(CancellationToken cancellationToken);
}