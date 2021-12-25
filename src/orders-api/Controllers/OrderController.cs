namespace OrdersApi.Controllers;

/* 
This controller processes orders asynchornoulsy from a Pub/Sub topic queue 
*/
[ApiController]
[Route("[controller]")]
public class OrderController : ControllerBase
{
    private readonly ILogger<OrderController> _logger;

    public OrderController(ILogger<OrderController> logger)
    {
        _logger = logger;
    }

    [Route("")]
    [HttpPost()]
    public async Task<ActionResult> SubmitOrderAsync([FromBody]Order order, [FromServices] DaprClient daprClient)
    {
        try
        {
            _logger.LogInformation($"SubmitOrderAsync - {order.StoreId}");
            await daprClient.PublishEventAsync("pubsub", "orders", order);
            return Ok();
        }
        catch (Exception e)
        {
            _logger.LogError($"SubmitOrderAsync - {order.StoreId} - Exception: " + e.Message);
            _logger.LogError($"SubmitOrderAsync - {order.StoreId} - Inner Exception: " + e.InnerException);
            return StatusCode(500);
        }
    }
}
