namespace Shared.Services;

public interface IEntityStateService 
{
    Task<EntityState> GetEntity(string identifier);
    Task SaveEntity(EntityState state);
    Task Seed();
}