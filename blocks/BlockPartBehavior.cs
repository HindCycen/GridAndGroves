#region

using Godot;

#endregion

/// <summary>
///     BlockPart 行为基类。每个行为定义一个积木部件被 Bot 触发时的效果。
///     子类必须覆写 CreateAction() 返回对应的 AbstractAction 类型。
/// </summary>
[GlobalClass]
public abstract partial class BlockPartBehavior : Resource {
    /// <summary>
    ///     将本行为转变为 AbstractAction，加入 ActionQueue 由调度器异步执行。
    ///     返回具体 Action 类型（DamageAction, ApplyStatusAction 等）以支持动画时长。
    ///     返回 null 表示本行为不需要 Action 入队（如纯方向修改行为）。
    /// </summary>
    public abstract AbstractAction CreateAction(Block block, BlockPart part);
}