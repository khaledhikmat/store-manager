namespace Shared.Events;

public record struct Order(string StoreId, int Units, double Revenue);