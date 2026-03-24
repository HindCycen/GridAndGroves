#region

using Godot;

#endregion

public partial class Main : Node2D {
    [Export] private BlockDef[] _availableBlockDefs;

    public override void _Ready() {
        // Glob 作为 Autoload 已经自动初始化了
    }
}