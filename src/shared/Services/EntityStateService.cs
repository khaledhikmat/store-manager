namespace Shared.Services;

using Shared.Models;

public class EntityStateService : IEntityStateService
{
    private const string DAPR_STORE_NAME = "statestore";
    private readonly DaprClient _daprClient;

    public EntityStateService(DaprClient client) 
    {
        _daprClient = client;
    }

    public async Task<EntityState> GetEntity(string identifier)
    {
        var stateEntry = await _daprClient.GetStateEntryAsync<EntityState>(DAPR_STORE_NAME, identifier);
        return stateEntry.Value;    
    }

    public async Task SaveEntity(EntityState state)
    {
        await _daprClient.SaveStateAsync<EntityState>(DAPR_STORE_NAME, state.Identifier, state);
    }
}