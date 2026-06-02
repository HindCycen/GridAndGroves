#region

using Godot;

#endregion

[GlobalClass]
public partial class EventRand : Resource {
    [Export] public EventDef[] PossibleEvents;
}