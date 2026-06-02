using Godot;

/// <summary>
/// 所有动作的基类。每个动作携带一个 duration，
/// 在此期间播放视觉效果，duration 归零时执行实际逻辑。
///
/// 设计对标 StS 的 AbstractGameAction：
/// - duration / startDuration：动作持续时长
/// - TickDuration()：每帧推进，归零时 isDone = true
/// - AddToBot() / AddToTop()：快捷加入当前 ActionQueue
/// - update()：子类实现具体行为
/// </summary>
public abstract class AbstractAction {
    /// <summary>当前剩余时长（秒）。归零时标记完成。</summary>
    protected float Duration { get; set; }

    /// <summary>初始时长，用于重置。</summary>
    protected float StartDuration { get; set; }

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

    protected AbstractAction() { }

    protected AbstractAction(float duration) {
        Duration = duration;
        StartDuration = duration;
    }

    /// <summary>
    /// 每帧由 ActionQueue 调用，驱动动作逻辑和视觉效果。
    /// 子类在此方法中实现具体行为，结束时将 IsDone 置为 true。
    /// </summary>
    public abstract void Update(float delta);

    /// <summary>
    /// 每帧递减 duration，归零时自动标记完成。
    /// 用于"等待一段时间后执行逻辑"的动作。
    /// </summary>
    protected void TickDuration(float delta) {
        Duration -= delta;
        if (Duration <= 0f) {
            Duration = 0f;
            IsDone = true;
        }
    }

    /// <summary>
    /// 将另一个动作追加到当前 ActionQueue 的末尾。
    /// </summary>
    protected void AddToBot(AbstractAction action) {
        ActionQueue.Instance?.AddToBottom(action);
    }

    /// <summary>
    /// 将另一个动作插入到当前 ActionQueue 的队首。
    /// 用于紧急动作（如反击触发），会在当前动作之后立即执行。
    /// </summary>
    protected void AddToTop(AbstractAction action) {
        ActionQueue.Instance?.AddToTop(action);
    }
}
