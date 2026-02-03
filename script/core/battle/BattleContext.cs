using Godot;
using System;

public partial class BattleContext : Node {
    [Signal] public delegate void BattleContextReadyEventHandler();
    [Signal] public delegate void BattleStartedEventHandler();
    [Signal] public delegate void TurnStartedEventHandler();
    [Signal] public delegate void TurnEndedEventHandler();
    [Signal] public delegate void BattleEndedEventHandler();
    [Signal] public delegate void TicTacEventHandler();

    public override void _Ready() => EmitSignalBattleContextReady();
    public void SayBattleStarted() => EmitSignalBattleStarted();
    public void SayTurnStarted() => EmitSignalTurnStarted();
    public void SayTurnEnded() => EmitSignalTurnEnded();
    public void SayBattleEnded() => EmitSignalBattleEnded();
    public void SayTicTac() => EmitSignalTicTac();
}
