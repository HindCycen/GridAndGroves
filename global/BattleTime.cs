#region

using Godot;

#endregion

/// <summary>
/// 战斗时间线信号中枢。对标 StS 的事件总线。
///
/// 提供战斗生命周期信号：
/// - 房间级：BattleStarted / BattleEnded / TurnStarted / TurnEnded
/// - TicTac 级：PreBlockExecute → BlockExecute → PostBlockExecute（对应打牌三段式）
///
/// 每次信号发出后自动触发对应 StatExecuteAt 的 StatBehavior 钩子。
/// </summary>
public partial class BattleTime : Node {
    // ─── 原有信号（保持向后兼容） ───
    [Signal]
    public delegate void BattleContextReadyEventHandler();

    [Signal]
    public delegate void BattleEndedEventHandler();

    [Signal]
    public delegate void BattleStartedEventHandler();

    [Signal]
    public delegate void TicTacEventHandler();

    [Signal]
    public delegate void TurnEndedEventHandler();

    [Signal]
    public delegate void TurnStartedEventHandler();

    // ─── 新增三段式 TicTac 信号 ───
    [Signal]
    public delegate void PreBlockExecuteEventHandler();

    [Signal]
    public delegate void BlockExecuteEventHandler();

    [Signal]
    public delegate void PostBlockExecuteEventHandler();

    public override void _Ready() {
        EmitSignalBattleContextReady();

        // 房间级信号 → 触发对应的 StatBehavior
        BattleStarted += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnBattleStarted);
        TurnStarted += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnTurnStarted);
        TurnEnded += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnTurnEnded);
        BattleEnded += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnBattleEnded);

        // TicTac 三段式信号 → 触发对应的 StatBehavior
        PreBlockExecute += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnPreBlockExecute);
        BlockExecute += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnBlockExecute);
        PostBlockExecute += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnPostBlockExecute);
    }

    /// <summary>
    /// 遍历所有 "stats" 组中的 Stat 节点，执行对应时机的钩子。
    /// </summary>
    private void ExecuteStatBehaviors(Glob.StatExecuteAt period) {
        var stats = GetTree().GetNodesInGroup("stats");
        foreach (var node in stats) {
            if (node is Stat stat && stat.Definition?.Behavior != null) {
                stat.Definition.Behavior.ExecuteAt(period);
            }
        }
    }

    // ─── 原有公开方法（保持向后兼容） ───

    public void SayBattleStarted() {
        EmitSignalBattleStarted();
    }

    public void SayTurnStarted() {
        EmitSignalTurnStarted();
    }

    public void SayTurnEnded() {
        EmitSignalTurnEnded();
    }

    public void SayBattleEnded() {
        EmitSignalBattleEnded();
    }

    /// <summary>
    /// 旧版 SayTicTac，保留向后兼容。
    /// 新版 Bot 应使用 SayPreBlockExecute / SayPostBlockExecute。
    /// </summary>
    public void SayTicTac() {
        EmitSignalTicTac();
    }

    // ─── 新增三段式 TicTac API ───

    /// <summary>
    /// Phase A：BlockPart 执行之前的阶段。
    /// 用于修饰性效果（加伤、减伤）、前置扣费等。
    /// </summary>
    public void SayPreBlockExecute() {
        EmitSignalPreBlockExecute();
    }

    /// <summary>
    /// Phase B：BlockPart.Execute() 自身产生 Action 的阶段。
    /// 由 Bot 在遇到 Block 后调用，各 Behavior 通过 addToBot/addToTop 入队。
    /// </summary>
    public void SayBlockExecute() {
        EmitSignalBlockExecute();
    }

    /// <summary>
    /// Phase C：BlockPart 执行之后的阶段。
    /// 用于触发类效果（荆棘、残杀、勒脖等效）。
    /// </summary>
    public void SayPostBlockExecute() {
        EmitSignalPostBlockExecute();
    }

    /// <summary>
    /// 一次完成三段式 TicTac（简便方法，Bot 用）。
    /// 调用顺序：PreBlock → Block → PostBlock。
    /// </summary>
    public void ExecuteFullTicTac() {
        // 本轮 PreBlock 产生的 Action 被入队到 ActionQueue
        SayPreBlockExecute();
        // BlockExecute 由 Bot 在 MoveToNextCell 中自行调用
        // PostBlock 在 Bot 完成 Block 处理后调用
    }
}
