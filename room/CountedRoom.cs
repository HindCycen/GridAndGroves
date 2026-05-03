using Godot;

public partial class CountedRoom : Room {
    public override void _Ready() {
        base._Ready();
        var player = GetTree().GetFirstNodeInGroup("Players") as Player;
        if (player != null) {
            player.RoomCount++;
            player.StageCount++;
        }
    }
}
