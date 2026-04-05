#region

using Godot;

#endregion

public partial class BattleTime : Node {
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

    public override void _Ready() {
        EmitSignalBattleContextReady();

        // Subscribe to battle events and trigger stat behaviors
        BattleStarted += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnBattleStarted);
        TurnStarted += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnTurnStarted);
        TicTac += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnTicTac);
        TurnEnded += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnTurnEnded);
        BattleEnded += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnBattleEnded);
    }

    private void ExecuteStatBehaviors(Glob.StatExecuteAt period) {
        var stats = GetTree().GetNodesInGroup("stats");
        foreach (var node in stats) {
            if (node is Stat stat && stat.Definition?.Behavior != null) {
                stat.Definition.Behavior.ExecuteAt(period);
            }
        }
    }

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

    public void SayTicTac() {
        EmitSignalTicTac();
    }
}