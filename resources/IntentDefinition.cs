#region

using Godot;

#endregion

[GlobalClass]
public partial class IntentDefinition : Resource {
    [Export] public string IntentName;
    [Export] public int RepeatCount = 1;
    [Export] public BlockPlacementDef[] BlockPlacements;
}
