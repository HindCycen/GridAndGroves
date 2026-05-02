using System.Collections.Generic;
using Godot;

public partial class CountedRoom : Room {
    private static readonly Dictionary<string, bool> VisitedRooms = new();

    private bool _hasCounted;

    public override void _Ready() {
        base._Ready();
        if (!_hasCounted) {
            var roomId = SceneFilePath;
            if (!VisitedRooms.ContainsKey(roomId)) {
                VisitedRooms[roomId] = true;
                var player = GetTree().GetFirstNodeInGroup("Players") as Player;
                if (player != null) {
                    player.RoomCount++;
                    player.StageCount++;
                }
                _hasCounted = true;
            }
        }
    }
}
