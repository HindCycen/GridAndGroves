#region

using System.Collections.Generic;
using Godot;

#endregion

/// <summary>
///     中央动作队列调度器。对标 StS 的 GameActionManager。
///     职责：
///     - 维护一个先进先出的动作队列
///     - 每帧推进当前动作（驱动视觉效果和逻辑）
///     - 提供 addToTop / addToBottom 两种入队方式以控制优先级
///     用法：作为 BattleRoom 的子节点添加，在 _Ready 中初始化。
///     通过 ActionQueue.Instance 全局访问。
/// </summary>
public partial class ActionQueue : Node {
    /// <summary>调度器所处的阶段。</summary>
    public enum QueuePhase {
        Idle,
        Executing
    }

    /// <summary>动作队列。addToBottom 追加到末尾，addToTop 插入到头部。</summary>
    private readonly List<AbstractAction> _actions = new();

    /// <summary>全局访问入口。每个 BattleRoom 中应只有一个 ActionQueue 实例。</summary>
    public static ActionQueue Instance { get; private set; }

    /// <summary>当前正在执行的动作。</summary>
    public AbstractAction CurrentAction { get; private set; }

    /// <summary>上一个执行完成的动作。</summary>
    public AbstractAction PreviousAction { get; private set; }

    public QueuePhase Phase { get; private set; } = QueuePhase.Idle;

    /// <summary>当前队列中是否有正在执行的动作。</summary>
    public bool IsBusy => Phase == QueuePhase.Executing;

    public override void _Ready() {
        Instance = this;
        Phase = QueuePhase.Idle;
    }

    public override void _ExitTree() {
        if (Instance == this) {
            Instance = null;
        }
    }

    public override void _Process(double delta) {
        if (Phase != QueuePhase.Executing) {
            return;
        }

        // 当前动作还在进行中 → 每帧推进
        if (CurrentAction != null && !CurrentAction.IsDone) {
            CurrentAction.Update((float) delta);
            return;
        }

        // 当前动作已完成 → 记录并取下一个
        if (CurrentAction != null && CurrentAction.IsDone) {
            PreviousAction = CurrentAction;
            CurrentAction = null;
        }

        PopNextAction();
    }

    /// <summary>
    ///     从队列中取出下一个动作执行。
    /// </summary>
    private void PopNextAction() {
        if (_actions.Count > 0) {
            CurrentAction = _actions[0];
            _actions.RemoveAt(0);
            Phase = QueuePhase.Executing;
            return;
        }

        // 队列为空 → 切回 Idle
        CurrentAction = null;
        Phase = QueuePhase.Idle;
    }

    // ──────────────────── 公共 API ────────────────────

    /// <summary>将动作追加到队列末尾（先进先出）。大多数动作使用此方法。</summary>
    public void AddToBottom(AbstractAction action) {
        _actions.Add(action);
        if (Phase == QueuePhase.Idle) {
            PopNextAction();
        }
    }

    /// <summary>将动作插入到队列头部。用于紧急/高优先级动作。</summary>
    public void AddToTop(AbstractAction action) {
        if (_actions.Count == 0) {
            _actions.Add(action);
        }
        else {
            _actions.Insert(0, action);
        }

        if (Phase == QueuePhase.Idle) {
            PopNextAction();
        }
    }

    /// <summary>清空所有队列（战斗结束时调用）。</summary>
    public void Clear() {
        _actions.Clear();
        CurrentAction = null;
        PreviousAction = null;
        Phase = QueuePhase.Idle;
    }

    /// <summary>主队列是否为空。</summary>
    public bool IsEmpty() {
        return _actions.Count == 0;
    }
}