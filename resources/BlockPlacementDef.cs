#region

using Godot;

#endregion

[GlobalClass]
public partial class BlockPlacementDef : Resource {
    [Export] public BlockDef Block;
    [Export] public Vector2I GridPosition;
    [Export] public int RandomOffsetRange = 1;
}