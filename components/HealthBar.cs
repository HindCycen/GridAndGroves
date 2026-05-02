#region

using Godot;

#endregion

public partial class HealthBar : TextureProgressBar {
    [Export] private HealthComponent _healthComponent;
    [Export] private ShieldComponent _shieldComponent;

    private Texture2D _healthBarMid;
    private Texture2D _shieldBarMid;

    public override void _Ready() {
        _healthBarMid = GD.Load<Texture2D>("res://components/healthbar/HealthBarMid.png");
        _shieldBarMid = GD.Load<Texture2D>("res://components/healthbar/ShieldBarMid.png");

        MinValue = 0;
        MaxValue = _healthComponent.MaxHealth;
        Value = _healthComponent.CurrentHealth;
        _healthComponent.HealthChanged += (current, max) => (Value, MaxValue) = (current, max);

        if (_shieldComponent != null) {
            UpdateMidTexture(_shieldComponent.CurrentShield);
            _shieldComponent.ShieldChanged += (current, _) => UpdateMidTexture(current);
        }
    }

    private void UpdateMidTexture(int shield) {
        TextureProgress = shield > 0 ? _shieldBarMid : _healthBarMid;
    }
}
