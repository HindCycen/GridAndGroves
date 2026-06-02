using Godot;

/// <summary>
/// 等待动作。不执行任何逻辑，仅消耗 duration。
/// 用于在动作序列中插入停顿。
/// </summary>
public class WaitAction : AbstractAction {
    public WaitAction(float duration) : base(duration) {
        ActionType = Glob.ActionType.Wait;
    }

    public override void Update(float delta) {
        TickDuration(delta);
    }
}
