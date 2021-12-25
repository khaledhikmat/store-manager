using System.Text.Json;

namespace ActorsApi.Actors;

public class EntityActor : Actor, IEntityActor, IRemindable
{
    // STATES
    private const string ENTITY_STATE_NAME = "entity";

    // REMINDERS
    private const string PROPOGATE_REMINDER_NAME = "propogate";

    // TIMERS
    private const string EXTERNALIZE_TIMER_NAME = "externalize";

    private DaprClient _daprClient;
    private IEntityStateService _externalizationService;

    public EntityActor(ActorHost host, DaprClient daprClient, IEntityStateService exterService) : base(host)
    {
        _daprClient = daprClient;
        _externalizationService = exterService;
    }

    protected override async Task OnActivateAsync()
    {
        Logger.LogInformation($"EntityActor - OnActivateAsync [{this.Id.ToString()}] - Entry");
        var actorState = await this.StateManager.TryGetStateAsync<EntityState>(ENTITY_STATE_NAME);
        if (!actorState.HasValue) 
        {
            Logger.LogInformation($"EntityActor - OnActivateAsync [{this.Id.ToString()}] - Set initial state");
            // Read actor configuration from an external store given the actor id 
            var entity = await this._externalizationService.GetEntity(this.Id.ToString());
            await this.StateManager.SetStateAsync(ENTITY_STATE_NAME, entity);
            Logger.LogInformation($"EntityActor - OnActivateAsync [{this.Id.ToString()}] - Store initial state");
        }

        //Set a timer to externalize actor state to an outside store
        await RegisterTimerAsync(
            EXTERNALIZE_TIMER_NAME,
            nameof(ExternalizationTimerCallback),
            null,
            TimeSpan.FromSeconds(10),
            TimeSpan.FromSeconds(180));
    }

    protected override async Task OnDeactivateAsync()
    {
        Logger.LogInformation($"EntityActor - OnDeactivateAsync [{this.Id.ToString()}] - Entry");
        await UnregisterTimerAsync(EXTERNALIZE_TIMER_NAME);
    }


    public async Task SubmitOrderAsync(Order order)
    {
        Logger.LogInformation($"EntityActor - SubmitOrderAsync [{this.Id.ToString()}] - Entry");
        //Register order locally
        var entityState = await this.StateManager.GetStateAsync<EntityState>(ENTITY_STATE_NAME);
        if (entityState != null)
        {
            Logger.LogInformation($"EntityActor - SubmitOrderAsync [{this.Id.ToString()}] - Processing order: {order.Units} - {order.Revenue}");
            int units = entityState.Units + order.Units;
            double revenue = entityState.Revenue + order.Revenue;
            entityState.Units = units;
            entityState.Revenue = revenue ;
            Logger.LogInformation($"EntityActor - enity state units: [{entityState.Units}] - revenue: [{entityState.Revenue}]");
            //await this.StateManager.SaveStateAsync();
            await this.StateManager.SetStateAsync(ENTITY_STATE_NAME, entityState);
            
            //Register a reminder to propogate to parent and return (to minimize actor execution so it does not block)
            if (!string.IsNullOrEmpty(entityState.ParentIdentifier)) {
                Logger.LogInformation($"EntityActor - SubmitOrderAsync [{this.Id.ToString()}] - Registering reminder");
                await RegisterReminderAsync(
                    PROPOGATE_REMINDER_NAME, 
                    ObjectToByteArray(order), 
                    TimeSpan.FromSeconds(1), // Fire in 1 second
                    TimeSpan.FromMilliseconds(-1) // To disable period signalling
                );    
            }
            else 
            {
                Logger.LogInformation($"EntityActor - SubmitOrderAsync [{this.Id.ToString()}] - Skipping reminder");
            }
        }
    }

    public async Task ReceiveReminderAsync(string reminderName, byte[] state, TimeSpan dueTime, TimeSpan period)
    {
        Logger.LogInformation($"EntityActor - ReceiveReminderAsync [{this.Id.ToString()}] - Entry");
        // Un-register reminder
        await UnregisterReminderAsync(PROPOGATE_REMINDER_NAME);

        //Propogate to parent 
        if (reminderName == PROPOGATE_REMINDER_NAME) {
            Logger.LogInformation($"EntityActor - ReceiveReminderAsync [{this.Id.ToString()}] - Processing {PROPOGATE_REMINDER_NAME} reminder");
            var order = ByteArrayToObject<Order>(state);        
            var entityState = await this.StateManager.GetStateAsync<EntityState>(ENTITY_STATE_NAME);
            if (order != null && entityState != null)
            {
                Logger.LogInformation($"EntityActor - ReceiveReminderAsync [{this.Id.ToString()}] - Calling SubmitOrderAsync on parent [{entityState.ParentIdentifier}]");
                var parent = ProxyFactory.CreateActorProxy<IEntityActor>(new ActorId(entityState.ParentIdentifier), nameof(EntityActor));
                await parent.SubmitOrderAsync(order);
            }
        }
    }

    public async Task ExternalizationTimerCallback(byte[] state)
    {
        Logger.LogInformation($"EntityActor - ExternalizationTimerCallback [{this.Id.ToString()}] - Entry");
        await this._externalizationService.SaveEntity(await this.StateManager.GetStateAsync<EntityState>(ENTITY_STATE_NAME));
    }
    
    private byte[] ObjectToByteArray(Object obj)
    {
        try
        {
            return JsonSerializer.SerializeToUtf8Bytes(obj);
        }
        catch (Exception e)
        {
            Logger.LogInformation($"EntityActor - ObjectToByteArray - failure: {e.Message}");
            return new byte[0];
        }
    }

    private T ByteArrayToObject<T>(byte[] byteArray)
    {
        try
        {
            //return JsonSerializer.Deserialize<T>(Encoding.UTF8.GetString(byteArray));
            return JsonSerializer.Deserialize<T>(byteArray);
        } catch(Exception e) {
            Logger.LogInformation($"EntityActor - ByteArrayToObject - failure: {e.Message}");
            return default(T);
        }
    }
}