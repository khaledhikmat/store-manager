namespace ActorsApi.Controllers;

/* 
This controller processes orders asynchornoulsy from a Pub/Sub topic queue 
*/
[ApiController]
[Route("[controller]")]
public class ProcessorController : ControllerBase
{
    private readonly ILogger<ProcessorController> _logger;

    public ProcessorController(ILogger<ProcessorController> logger)
    {
        _logger = logger;
    }

    [Topic("pubsub", "orders")]
    [Route("orders")]
    [HttpPost()]
    public async Task<ActionResult> ProcessOrderAsync(Order order)
    {
        try
        {
             _logger.LogInformation($"ProcessOrderAsync - {order.StoreId}");
           var actorId = new ActorId(order.StoreId);
            var proxy = ActorProxy.Create<IEntityActor>(actorId, nameof(EntityActor));
            await proxy.SubmitOrderAsync(order);
            return Ok();
        }
        catch (Exception e)
        {
            _logger.LogError($"ProcessOrderAsync - {order.StoreId} - Exception: " + e.Message);
            _logger.LogError($"ProcessOrderAsync - {order.StoreId} - Inner Exception: " + e.InnerException);
            return StatusCode(500);
        }
    }
}
