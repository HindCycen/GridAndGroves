#region

using Godot;

#endregion

[GlobalClass]
public partial class StageEnemyChartDef : Resource {
    [Export] public EnemyChartDef[] BossChart;
    [Export] public EnemyChartDef[] EliteChart;
    [Export] public EnemyChartDef[] StrongEnemyChart;
    [Export] public EnemyChartDef[] WeakEnemyChart;
}