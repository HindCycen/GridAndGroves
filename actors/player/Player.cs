#region

using Godot;

#endregion

public partial class Player : Node2D {
    public int RoomCount { get; set; }
    public int StageCount { get; set; }

    public override void _Ready() {
        AddToGroup("Players");
    }

    public override void _Process(double delta) {
    }
}
