#region

using Godot;

#endregion

[GlobalClass]
public partial class EnemyDefinition : Resource {
    [Export] public string EnemyName;
    [Export] public int MaxHealth = 50;
    [Export] public int AttackDamage = 10;
    [Export] public IntentDefinition[] IntentCycle;
}
