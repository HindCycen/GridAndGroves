#region

using Godot;

#endregion

public partial class Enemy : Node2D {
    public override void _Ready() {
        AddToGroup("Enemies");
    }
}
