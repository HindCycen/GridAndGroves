#region

using Godot;

#endregion

[GlobalClass]
public partial class DataResource : Resource {
    // ── Player State ──
    [Export] public int PlayerCurrentHealth;
    [Export] public int PlayerMaxHealth;

    [Export] public string[] PlayerDeckBlockNames = [];

    [Export] public string[] PlayerStatNames = [];
    [Export] public int[] PlayerStatValues = [];

    // ── Floor State ──
    [Export] public int StageCount;
    [Export] public int RoomCount;

    [Export] public int[] GridClickable = [];
    [Export] public int[] GridLeft = [];
    [Export] public string StageDefPath;

    // ── Random State ──
    [Export] public int Seed;
    [Export] public int MapRandUsage;
    [Export] public int MonsterRandUsage;
    [Export] public int RewardRandUsage;
    [Export] public int ChestRandUsage;
    [Export] public int MiscRandUsage;
    [Export] public int PileRandUsage;
}
