namespace ActorsApi.Actors;

public interface IEntityActor : IActor {
    public Task SubmitOrderAsync(Order order); 
}
