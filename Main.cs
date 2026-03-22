#region

using Godot;

#endregion

public partial class Main : Node2D {
    [Export] private BlockDef[] _availableBlockDefs;

    public override void _Ready() {
        Global.InitRng();
        Global.InitGrids();
    }
}