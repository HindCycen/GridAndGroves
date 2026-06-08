#region

using Godot;

#endregion

/// <summary>
///     所有动作的基类。对标 StS 的 AbstractGameAction。
///     - duration / startDuration：动作持续时长与初始值
///     - TickDuration()：每帧推进，归零时 isDone = true
///     - AddToBot() / AddToTop()：快捷加入当前 ActionManager
///     - Update()：子类实现具体行为
/// </summary>
public abstract class AbstractGameAction {
    protected AbstractGameAction() {
    }

    protected AbstractGameAction(float duration) {
        Duration = duration;
        StartDuration = duration;
    }

    /// <summary>当前剩余时长（秒）。归零时标记完成。</summary>
    public float Duration { get; set; }

    /// <summary>初始时长。同 StS startDuration，用于显示进度或重置参考。</summary>
    public float StartDuration { get; protected set; }

    /// <summary>动作是否已完成。</summary>
    public bool IsDone { get; protected set; }

    /// <summary>动作类型，用于分类和调试。</summary>
    public Glob.ActionType ActionType { get; set; } = Glob.ActionType.Special;

    /// <summary>动作的发出者（Block / Creature / null）。</summary>
    public Node Source { get; set; }

    /// <summary>动作的目标（Enemy / Player / null）。</summary>
    public Node Target { get; set; }

    /// <summary>通用数值参数（伤害值、治疗量等）。</summary>
    public int Amount { get; set; }

    /// <summary>
    ///     此 Action 被执行后，其来源 Block 是否被移出本场战斗（不进入弃牌堆也不参与洗牌）。
    ///     由 Bot.ProcessBlockPart() 在入队后检测，如果为 true 则立即将 Block 从 PlacedPile 移除并释放。
    /// </summary>
    public virtual bool ExhaustSourceBlock => false;

    /// <summary>
    ///     每帧由 ActionManager 调用，驱动动作逻辑和视觉效果。
    ///     子类在此方法中实现具体行为，结束时将 IsDone 置为 true。
    /// </summary>
    public abstract void Update(float delta);

    /// <summary>
    ///     每帧递减 duration，归零时自动标记完成。
    ///     用于"等待一段时间后执行逻辑"的动作。
    /// </summary>
    protected void TickDuration(float delta) {
        Duration -= delta;
        if (Duration <= 0f) {
            Duration = 0f;
            IsDone = true;
        }
    }

    /// <summary>
    ///     将另一个动作追加到当前 ActionManager 的末尾。
    /// </summary>
    protected void AddToBot(AbstractGameAction action) {
        ActionManager.Instance?.AddToBottom(action);
    }

    /// <summary>
    ///     将另一个动作插入到当前 ActionManager 的队首。
    ///     用于紧急动作（如反击触发），会在当前动作之后立即执行。
    /// </summary>
    protected void AddToTop(AbstractGameAction action) {
        ActionManager.Instance?.AddToTop(action);
    }
}
