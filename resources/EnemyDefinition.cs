#region

using Godot;

#endregion

[GlobalClass]
public partial class EnemyDefinition : Resource {
    [Export] public int AttackDamage = 10;
    [Export] public string EnemyName;
    [Export] public IntentDefinition[] IntentCycle;
    [Export] public int MaxHealth = 50;
}