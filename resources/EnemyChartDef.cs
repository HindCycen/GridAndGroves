#region

using Godot;

#endregion

[GlobalClass]
public partial class EnemyChartDef : Resource {
    [Export] public EnemyDefinition[] EnemyDefs;
}