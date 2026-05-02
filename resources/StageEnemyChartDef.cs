using Godot;

[GlobalClass]
public partial class StageEnemyChartDef : Resource {
    [Export] public EnemyChartDef[] WeakEnemyChart;
    [Export] public EnemyChartDef[] StrongEnemyChart;
    [Export] public EnemyChartDef[] EliteChart;
    [Export] public EnemyChartDef[] BossChart;
}
