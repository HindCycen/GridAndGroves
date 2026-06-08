#region

using System;

#endregion

/// <summary>
///     回调动作。立即执行一个委托函数，主要用于瞬时逻辑（如方向修改、状态移除）。
///     对标 StS 中的回调模式，支持 ExhaustSourceBlock 标记。
/// </summary>
public class CallbackAction : AbstractGameAction {
    private readonly Action _callback;
    private readonly bool _exhaustSourceBlock;

    public CallbackAction(Action callback, Glob.ActionType actionType = Glob.ActionType.Callback, bool exhaustSourceBlock = false) {
        _callback = callback;
        _exhaustSourceBlock = exhaustSourceBlock;
        ActionType = actionType;
        Duration = 0f;
    }

    public override bool ExhaustSourceBlock => _exhaustSourceBlock;

    public override void Update(float delta) {
        if (IsDone) {
            return;
        }

        _callback?.Invoke();
        IsDone = true;
    }
}
