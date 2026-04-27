#region

using Godot;

#endregion

[GlobalClass]
public partial class IntentDefinition : Resource {
    [Export] public BlockPlacementDef[] BlockPlacements;
    [Export] public string IntentName;
    [Export] public int RepeatCount = 1;
}