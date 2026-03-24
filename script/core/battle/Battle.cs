#region

using Godot;

#endregion

public partial class Battle : Node2D {
    public override void _Ready() {
        Global.AutoRegisterBlocks();
        Global.InitRng();
        Global.InitGrids();
        Global.GetBlock("ExampleBlock", new Vector2(100, 100), this);
        Global.GetBlock("ExampleMoveRight", new Vector2(200, 200), this);
    }
}