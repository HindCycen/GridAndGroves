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
    ///     将本行为转变为 AbstractGameAction，加入 ActionManager 由调度器异步执行。
    ///     返回具体 Action 类型（DamageAction, ApplyStatusAction 等）以支持动画时长。
    ///     返回 null 表示本行为不需要 Action 入队（如纯方向修改行为）。
    /// </summary>
    public abstract AbstractGameAction CreateAction(Block block, BlockPart part);

    /// <summary>
    ///     此 Behavior 是否阻止其所属 Block 在回合结束时被清除。
    ///     为 true 时，Block 会保留在网格上跨回合，不会进入弃牌堆。
    ///     子类可覆写返回 true 来实现"驻留"效果。
    /// </summary>
    public virtual bool PreventsClear => false;
}