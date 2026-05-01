#region

using Godot;

#endregion

[GlobalClass]
public partial class StatDef : Resource {
    [Export] public StatBehavior Behavior;
    [Export] public bool CanGoNegative;
    [Export] public string Description;
    [Export] public Texture2D Icon;
    [Export] public int MaxValue;
    [Export] public string StatName;
}