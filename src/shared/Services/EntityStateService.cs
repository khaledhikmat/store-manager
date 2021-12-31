namespace Shared.Services;

using Shared.Models;

public class EntityStateService : IEntityStateService
{
    private readonly DaprClient _daprClient;

    public EntityStateService(DaprClient client) 
    {
        _daprClient = client;
    }

    public async Task<EntityState> GetEntity(string identifier)
    {
        var stateEntry = await _daprClient.GetStateEntryAsync<EntityState>(Constants.DAPR_STORE_NAME, identifier);
        return stateEntry.Value;    
    }

    public async Task SaveEntity(EntityState state)
    {
        await _daprClient.SaveStateAsync<EntityState>(Constants.DAPR_STORE_NAME, state.Identifier, state);
    }

    public async Task Seed() 
    {
        var seeder = await _daprClient.GetStateAsync<string>(Constants.DAPR_STORE_NAME, Constants.DAPR_STORE_SEEDER_KEY);
        if (string.IsNullOrEmpty(seeder)) 
        {
            Console.WriteLine($"Seed key is not found....seeding data....");

            // Store seeder key so we can find it next time
            await _daprClient.SaveStateAsync<string>(Constants.DAPR_STORE_NAME, Constants.DAPR_STORE_SEEDER_KEY, Constants.DAPR_STORE_SEEDER_VALUE);

            // Seed the store with some entities so actors can initialize
            List<EntityState> entities = new List<EntityState> {
                new EntityState() {Identifier = "ST-GLOBAL", Name = "Global", ParentIdentifier = "", ParentName = "", Units = 0, Revenue = 0},
                new EntityState() {Identifier = "ST-USA", Name = "USA", ParentIdentifier = "ST-GLOBAL", ParentName = "Global", Units = 0, Revenue = 0},
                new EntityState() {Identifier = "ST-USA-TX", Name = "Texas", ParentIdentifier = "ST-USA", ParentName = "USA", Units = 0, Revenue = 0},
                new EntityState() {Identifier = "ST-USA-TX-SAT", Name = "San Antonio", ParentIdentifier = "ST-USA-TX", ParentName = "Texas", Units = 0, Revenue = 0},
                new EntityState() {Identifier = "ST-USA-TX-SAT-LEONS", Name = "Leon Spring", ParentIdentifier = "ST-USA-TX-SAT", ParentName = "San Antonio", Units = 0, Revenue = 0},
                new EntityState() {Identifier = "ST-USA-TX-SAT-LCAN", Name = "La Centera", ParentIdentifier = "ST-USA-TX-SAT", ParentName = "San Antonio", Units = 0, Revenue = 0},
                new EntityState() {Identifier = "ST-USA-TX-SAT-RIM", Name = "Rim", ParentIdentifier = "ST-USA-TX-SAT", ParentName = "San Antonio", Units = 0, Revenue = 0},
                new EntityState() {Identifier = "ST-USA-TX-SAT-DOMN", Name = "Dominion", ParentIdentifier = "ST-USA-TX-SAT", ParentName = "San Antonio", Units = 0, Revenue = 0}
            };

            foreach(EntityState entity in entities) 
            {
                Console.WriteLine($"Seeding {entity.Identifier}");
                await _daprClient.SaveStateAsync<EntityState>(Constants.DAPR_STORE_NAME, entity.Identifier, entity);
            }
        }
    }
}