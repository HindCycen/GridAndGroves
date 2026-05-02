using Godot;

[GlobalClass]
public partial class EventDef : Resource {
    [Export] public string EventDesc;
    [Export] public EventChoiceDef[] Choices;
}
