using Godot;

/// <summary>
/// 施加状态动作。duration 归零后将指定 Stat 添加到目标的 StatsComponent。
/// </summary>
public class ApplyStatusAction : AbstractAction {
    private readonly StatDef _statDef;
    private readonly int _initialValue;

    public ApplyStatusAction(Node target, StatDef statDef, int initialValue, float duration = 0.3f) : base(duration) {
        Target = target;
        _statDef = statDef;
        _initialValue = initialValue;
        Amount = initialValue;
        ActionType = Glob.ActionType.ApplyStatus;
    }

    public override void Update(float delta) {
        if (IsDone) return;

        TickDuration(delta);
        if (!IsDone) return;

        if (Target is Node2D targetNode) {
            var rendering = targetNode.GetNodeOrNull<RenderingComponent>("RenderingComponent");
            if (rendering?.StatsComponent != null) {
                var stats = rendering.StatsComponent;
                if (!stats.HasStatus(_statDef.StatName)) {
                    var stat = new Stat { Definition = _statDef };
                    stats.AddStatus(stat);
                    stat.AddValue(_initialValue);
                }
                else {
                    var existingStat = stats.GetStatus(_statDef.StatName);
                    existingStat?.AddValue(_initialValue);
                }
            }
        }
    }
}
