using Godot;

[GlobalClass]
public partial class StatDef : Resource {
    [Export] public string StatName;
    [Export] public int MaxValue;
    [Export] public bool CanGoNegative;
    [Export] public Image Icon;
    [Export] public StatBehavior Behavior;
}