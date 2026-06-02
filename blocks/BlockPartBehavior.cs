using Godot;

/// <summary>
/// BlockPart 行为基类。每个行为定义一个积木部件被 Bot 触发时的效果。
///
/// 改版：
/// - Execute() 仍然保留（同步执行，用于旧流程调试）
/// - CreateAction() 新增（返回 AbstractAction，用于新队列流程）
///   默认实现是将 Execute() 包装为 CallbackAction。
///   子类可覆写返回具体的 Action 类型（DamageAction, ApplyStatusAction 等）
/// </summary>
[GlobalClass]
public abstract partial class BlockPartBehavior : Resource {
    /// <summary>
    /// 同步执行行为逻辑。（旧接口，逐渐弃用）
    /// </summary>
    public abstract void Execute(Block block, BlockPart part);

    /// <summary>
    /// 将本行为转变为 AbstractAction，加入 ActionQueue 由调度器异步执行。
    /// 默认实现：将 Execute() 包装为 CallbackAction（duration=0，立即执行）。
    /// 子类应覆写返回具体的 Action 类型以支持动画时长。
    /// </summary>
    public virtual AbstractAction CreateAction(Block block, BlockPart part) {
        return new CallbackAction(() => Execute(block, part));
    }
}
