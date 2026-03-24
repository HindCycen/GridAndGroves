#region

using Godot;
using System;

#endregion

public partial class Stat : Node {
    [Signal]
    public delegate void ValueChangedEventHandler(int current, int max);

    [Export] public StatDef Definition;

    [Export] public int CurrentValue { get; private set; }

    public bool IsFull => CurrentValue >= Definition.MaxValue;

    public bool IsEmpty => !Definition.CanGoNegative && CurrentValue <= 0;

    public override void _Ready() {
        CurrentValue = 0;
        Definition.Behavior.SetBelongingStat(this);
    }

    public void AddValue(int amount) {
        if (amount < 0) {
            throw new ArgumentException("增加值不能为负数");
        }

        CurrentValue = Math.Min(Definition.MaxValue, CurrentValue + amount);
        EmitSignal(SignalName.ValueChanged, CurrentValue, Definition.MaxValue);
    }

    public void ReduceValue(int amount) {
        if (amount < 0) {
            throw new ArgumentException("减少值不能为负数");
        }

        CurrentValue = Definition.CanGoNegative
            ? CurrentValue - amount
            : Math.Max(0, CurrentValue - amount);
        EmitSignal(SignalName.ValueChanged, CurrentValue, Definition.MaxValue);
    }

    public void SetValue(int value) {
        if (!Definition.CanGoNegative && value < 0) {
            throw new ArgumentException("当前值不能为负数");
        }

        CurrentValue = Definition.CanGoNegative
            ? Math.Min(Definition.MaxValue, value)
            : Math.Min(Definition.MaxValue, Math.Max(0, value));
        EmitSignal(SignalName.ValueChanged, CurrentValue, Definition.MaxValue);
    }
}