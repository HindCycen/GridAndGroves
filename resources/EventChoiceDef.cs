#region

using Godot;

#endregion

[GlobalClass]
public partial class EventChoiceDef : Resource {
    [Export] public EventActionType ActionType;
    [Export] public int ActionValue;
    [Export] public string Description;
    [Export] public string Name;
    [Export] public string ResultDescription;
}

public enum EventActionType {
    None,
    HealPlayer,
    DamagePlayer,
    AddGold,
    RemoveGold,
    AddBlockToDeck,
    RemoveBlockFromDeck
}