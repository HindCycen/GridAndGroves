using Godot;
using System;

public partial class HealthBar : TextureProgressBar {
    [Export] private HealthComponent _healthComponent;

    public override void _Ready() {
        MinValue = 0;
        MaxValue = _healthComponent.MaxHealth;
        Value = _healthComponent.CurrentHealth;
        _healthComponent.HealthChanged += (current, max) => (Value, MaxValue) = (current, max);
    }
}