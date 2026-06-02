#region

using Godot;

#endregion

[GlobalClass]
public partial class EventDef : Resource {
    [Export] public EventChoiceDef[] Choices;
    [Export] public string EventDesc;
}