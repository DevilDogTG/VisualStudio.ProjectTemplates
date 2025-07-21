namespace DMNSN.Templates.Project.WorkerApp.Interfaces.Services;

public interface IAppService
{
    Task RunProcessAsync(CancellationToken cancellationToken);
}