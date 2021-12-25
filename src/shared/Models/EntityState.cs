namespace Shared.Models;

public record struct EntityState 
{
    public string Identifier { get; set; }
    public string Name { get; set; }
    public string ParentIdentifier { get; set; }
    public string ParentName { get; set; }
    public int Units { get; set; }
    public double Revenue { get; set; }

    public EntityState(string id, string name, string parentId, string parentName, int units, double revenue) 
    {
        this.Identifier = id;
        this.Name = name;
        this.ParentIdentifier = parentId;
        this.ParentName = parentName;
        this.Units = units;
        this.Revenue = revenue;
    }
}