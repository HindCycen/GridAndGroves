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
