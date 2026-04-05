#region

using Godot;

#endregion

public partial class Battle : Node2D {
    public override void _Ready() {
        Glob.GetBlock("ExampleBlock", new Vector2(100, 100), this);
        Glob.GetBlock("ExampleMoveRight", new Vector2(200, 200), this);
    }
}