namespace ActorsApi.Controllers;

/* 
This controller processes orders asynchornoulsy from a Pub/Sub topic queue 
*/
[ApiController]
[Route("[controller]")]
public class ProcessorController : ControllerBase
{
    private readonly ILogger<ProcessorController> _logger;
    private IEntityStateService _externalizationService;

    public ProcessorController(IEntityStateService service, ILogger<ProcessorController> logger)
    {
        _logger = logger;
        _externalizationService = service;
    }

    [Topic("pubsub", "orders")]
    [Route("orders")]
    [HttpPost()]
    public async Task<ActionResult> ProcessOrderAsync(Order order)
    {
        try
        {
            _logger.LogInformation($"ProcessOrderAsync - {order.StoreId}");

            // Not the best way, but check to make sure that the actors have data to initialize
            await _externalizationService.Seed();

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
