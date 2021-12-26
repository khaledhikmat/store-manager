using Dapr.Client;
using Shared.Events;

Console.WriteLine("Pumper to call orders API to pump orders into the application ");
var daprClient = new DaprClientBuilder().Build();

List<string> stores = new List<string> {
    "ST-USA-TX-SAT-LEONS",
    "ST-USA-TX-SAT-LCAN",
    "ST-USA-TX-SAT-RIM",
    "ST-USA-TX-SAT-DOMN"
};

foreach (string store in stores)
{
    Console.WriteLine($"Submitting an order for store: {store}");

    try 
    {
        var order = new Order(store, 11, 617);
        await daprClient.InvokeMethodAsync<Order>("storemanagerorders", "order", order);    
    }
    catch (Exception e) 
    {
        Console.WriteLine($"Invocation error: {e.Message}");
    }
    finally
    {
        await Task.Delay(3000);
    }
}
