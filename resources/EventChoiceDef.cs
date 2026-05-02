using Godot;

[GlobalClass]
public partial class EventChoiceDef : Resource {
    [Export] public string Name;
    [Export] public string Description;
    [Export] public string ResultDescription;
    [Export] public EventActionType ActionType;
    [Export] public int ActionValue;
}

public enum EventActionType {
    None,
    HealPlayer,
    DamagePlayer,
    AddGold,
    RemoveGold,
    AddBlockToDeck,
    RemoveBlockFromDeck,
}
