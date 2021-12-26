/* 
Please note that I had to make the app-id equals the actors app id so I can share the state storage.
Dapr seems to append the application name to the Redis keys!! 
*/
using Dapr.Client;
using Shared.Services;
using Shared.Models;

Console.WriteLine("Seeder to store initial state for the application.");
var daprClient = new DaprClientBuilder().Build();
var service = new EntityStateService(daprClient);

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
    Console.WriteLine($"Storing {entity.Identifier}");
    await service.SaveEntity(entity);    
    await Task.Delay(1000);
}
