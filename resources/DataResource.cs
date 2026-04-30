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

    // ── Random State ──
    [Export] public int Seed;
    [Export] public int MapRandUsage;
    [Export] public int MonsterRandUsage;
    [Export] public int RewardRandUsage;
    [Export] public int ChestRandUsage;
    [Export] public int MiscRandUsage;
    [Export] public int PileRandUsage;
}
