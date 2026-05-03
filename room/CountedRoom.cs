using Godot;

public partial class CountedRoom : Room {
    public override void _Ready() {
        base._Ready();
        if (_saveLoad?.Data != null) {
            _saveLoad.Data.RoomCount++;
        }
    }
}
