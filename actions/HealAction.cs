#region

using Godot;

#endregion

/// <summary>
///     治疗动作。duration 归零后执行治疗逻辑。
/// </summary>
public class HealAction : AbstractAction {
    public HealAction(Node target, int amount, float duration = 0.3f) : base(duration) {
        Target = target;
        Amount = amount;
        ActionType = Glob.ActionType.Heal;
    }

    public override void Update(float delta) {
        if (IsDone) {
            return;
        }

        TickDuration(delta);
        if (!IsDone) {
            return;
        }

        if (Target is Node2D targetNode) {
            var hc = targetNode.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
            hc?.Heal(Amount);
        }
    }
}