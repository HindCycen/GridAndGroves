#region

using System;
using Godot;

#endregion

[GlobalClass]
public partial class DefendComponent : Node {
    [Signal]
    public delegate void DefendChangedEventHandler(int current, int max);

    [Export] public int MaxDefend { get; private set; } = 999;

    [Export] public int CurrentDefend { get; private set; }

    public override void _Ready() {
        CurrentDefend = 0;
        var battleTime = GetTree().Root.GetNode<BattleTime>("BattleTime");
        battleTime!.TurnEnded += () => { CurrentDefend = 0; };
    }

    public void AddDefend(int amount) {
        if (amount < 0) {
            throw new ArgumentException("防御增加值不能为负数");
        }

        CurrentDefend = Math.Min(MaxDefend, CurrentDefend + amount);
        EmitSignal(SignalName.DefendChanged, CurrentDefend, MaxDefend);
    }

    public void ReduceDefend(int amount) {
        if (amount < 0) {
            throw new ArgumentException("防御减少值不能为负数");
        }

        CurrentDefend = Math.Max(0, CurrentDefend - amount);
        EmitSignal(SignalName.DefendChanged, CurrentDefend, MaxDefend);
    }

    public void SetMaxDefend(int value) {
        if (value <= 0) {
            throw new ArgumentException("最大防御值必须大于 0");
        }

        MaxDefend = value;
        CurrentDefend = Math.Min(CurrentDefend, MaxDefend);
        EmitSignal(SignalName.DefendChanged, CurrentDefend, MaxDefend);
    }
}