using Godot;

[GlobalClass]
public partial class StageDef : Resource {
    [Export] public StageEnemyChartDef StageEnemyChart;
    [Export] public EventRand StageEventRand;
}
