#region

using System;
using Godot;

#endregion

public partial class HealthComponent : Node {
    [Signal]
    public delegate void DiedEventHandler();

    [Signal]
    public delegate void HealthChangedEventHandler(int current, int max);

    [Export] public int MaxHealth { get; private set; } = 100;

    [Export] public int CurrentHealth { get; private set; }
    public bool IsDead => CurrentHealth <= 0;

    public override void _Ready() {
        CurrentHealth = MaxHealth;
    }

    public void TakeDamage(int damage) {
        if (damage < 0) {
            throw new ArgumentException("伤害值不能为负数");
        }

        CurrentHealth = Math.Max(0, CurrentHealth - damage);
        EmitSignal(SignalName.HealthChanged, CurrentHealth, MaxHealth);

        if (IsDead) {
            EmitSignal(SignalName.Died);
        }
    }

    public void Heal(int amount) {
        if (amount < 0) {
            throw new ArgumentException("治疗值不能为负数");
        }

        CurrentHealth = Math.Min(MaxHealth, CurrentHealth + amount);
        EmitSignal(SignalName.HealthChanged, CurrentHealth, MaxHealth);
    }

    public void SetMaxHealth(int value) {
        if (value <= 0) {
            throw new ArgumentException("最大生命值必须大于0");
        }

        MaxHealth = value;
        CurrentHealth = Math.Min(CurrentHealth, MaxHealth);
        EmitSignal(SignalName.HealthChanged, CurrentHealth, MaxHealth);
    }
}