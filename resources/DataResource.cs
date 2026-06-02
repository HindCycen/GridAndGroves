#region

using Godot;

#endregion

[GlobalClass]
public partial class DataResource : Resource {
    [Export] public int ChestRandUsage;

    [Export] public int[] GridClickable = [];
    [Export] public int[] GridIsBattleCell = [];
    [Export] public int[] GridLeft = [];
    [Export] public int MapRandUsage;
    [Export] public int MiscRandUsage;
    [Export] public int MonsterRandUsage;

    [Export] public int PileRandUsage;

    // ── Player State ──
    [Export] public int PlayerCurrentHealth;

    [Export] public string[] PlayerDeckBlockNames = [];
    [Export] public int PlayerMaxHealth;

    [Export] public string[] PlayerStatNames = [];
    [Export] public int[] PlayerStatValues = [];
    [Export] public int RewardRandUsage;
    [Export] public int RoomCount;

    // ── Random State ──
    [Export] public int Seed;

    // ── Floor State ──
    [Export] public int StageCount;
    [Export] public string StageDefPath;
}