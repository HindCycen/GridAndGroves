#region

using Godot;

#endregion

[GlobalClass]
public partial class EnemyDefinition : Resource {
    [Export] public int AttackDamage = 10;
    [Export] public string EnemyName;
    [Export] public Texture2D Image;
    [Export] public IntentDefinition[] IntentCycle;
    [Export] public StatDef[] InitialStats;
    [Export] public int MaxHealth = 50;
}