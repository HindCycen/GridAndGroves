#region

using System;
using Godot;

#endregion

[GlobalClass]
public partial class ShieldComponent : Node {
    [Signal]
    public delegate void ShieldChangedEventHandler(int current, int max);

    [Export] public int MaxShield { get; private set; } = 999;

    [Export] public int CurrentShield { get; private set; }

    public override void _Ready() {
        CurrentShield = 0;
        var battleTime = GetTree().Root.GetNode<BattleTime>("BattleTime");
        battleTime!.TurnEnded += () => { CurrentShield = 0; };
    }

    public void AddShield(int amount) {
        if (amount < 0) {
            throw new ArgumentException("防御增加值不能为负数");
        }

        CurrentShield = Math.Min(MaxShield, CurrentShield + amount);
        EmitSignal(SignalName.ShieldChanged, CurrentShield, MaxShield);
    }

    public void ReduceShield(int amount) {
        if (amount < 0) {
            throw new ArgumentException("防御减少值不能为负数");
        }

        CurrentShield = Math.Max(0, CurrentShield - amount);
        EmitSignal(SignalName.ShieldChanged, CurrentShield, MaxShield);
    }

    public void SetMaxShield(int value) {
        if (value <= 0) {
            throw new ArgumentException("最大防御值必须大于 0");
        }

        MaxShield = value;
        CurrentShield = Math.Min(CurrentShield, MaxShield);
        EmitSignal(SignalName.ShieldChanged, CurrentShield, MaxShield);
    }
}
