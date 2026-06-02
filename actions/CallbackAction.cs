using System;
using Godot;

/// <summary>
/// 回调动作。立即执行一个委托函数，主要用于瞬时逻辑（如方向修改、状态移除）。
/// duration = 0，下一帧即完成。
/// </summary>
public class CallbackAction : AbstractAction {
    private readonly Action _callback;

    public CallbackAction(Action callback, Glob.ActionType actionType = Glob.ActionType.Callback) {
        _callback = callback;
        ActionType = actionType;
        Duration = 0f;
        StartDuration = 0f;
    }

    public override void Update(float delta) {
        if (IsDone) return;
        _callback?.Invoke();
        IsDone = true;
    }
}
