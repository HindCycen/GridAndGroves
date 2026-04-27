#region

using Godot;

#endregion

public partial class Player : Node2D {
    public override void _Ready() {
        AddToGroup("Players");
    }

    public override void _Process(double delta) {
    }
}