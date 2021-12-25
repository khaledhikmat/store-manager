namespace EntitiesApi.Controllers;

/* 
This controller queries entities by id. It could use the actors instead of querying the state store.
But I wanted the actors to be free to process orders without being blocked. 
*/
[ApiController]
[Route("[controller]")]
public class EntityController : ControllerBase
{
    private readonly ILogger<EntityController> _logger;
    private readonly IEntityStateService _externalizationService;

    public EntityController(ILogger<EntityController> logger, IEntityStateService exterService)
    {
        _logger = logger;
        _externalizationService = exterService;
    }

    [Route("{id}")]
    [HttpGet()]
    public async Task<ActionResult> GetEntityById(string id)
    {
        try
        {
            _logger.LogInformation($"GetEntityById - {id}");
            return Ok(await _externalizationService.GetEntity(id));
        }
        catch (Exception e)
        {
            _logger.LogError($"GetEntityById - {id} - Exception: " + e.Message);
            _logger.LogError($"GetEntityById - {id} - Inner Exception: " + e.InnerException);
            return StatusCode(500);
        }
    }
}
