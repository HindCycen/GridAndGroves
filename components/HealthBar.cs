#region

using Godot;

#endregion

public partial class HealthBar : TextureProgressBar {
    private Texture2D _healthBarMid;
    [Export] private HealthComponent _healthComponent;
    private Texture2D _shieldBarMid;
    [Export] private ShieldComponent _shieldComponent;

    public override void _Ready() {
        _healthBarMid = GD.Load<Texture2D>("res://components/healthbar/HealthBarMid.png");
        _shieldBarMid = GD.Load<Texture2D>("res://components/healthbar/ShieldBarMid.png");

        MinValue = 0;
        MaxValue = _healthComponent.MaxHealth;
        Value = _healthComponent.CurrentHealth;
        _healthComponent.HealthChanged += (current, max) => (Value, MaxValue) = (current, max);

        // 自动查找 ShieldComponent（如果 Export 没绑）
        var shield = _shieldComponent;
        if (shield == null) {
            shield = ResolveShieldComponent();
        }

        if (shield != null) {
            _shieldComponent = shield;
            UpdateMidTexture(shield.CurrentShield);
            shield.ShieldChanged += (current, _) => UpdateMidTexture(current);
        }
    }

    private void UpdateMidTexture(int shield) {
        TextureProgress = shield > 0 ? _shieldBarMid : _healthBarMid;
    }

    /// <summary>
    ///     向上遍历场景树查找 ShieldComponent。
    /// </summary>
    private ShieldComponent ResolveShieldComponent() {
        var shield = GetNodeOrNull<ShieldComponent>("%ShieldComponent");
        if (shield != null) return shield;

        var parent = GetParent();
        while (parent != null) {
            shield = parent.GetNodeOrNull<ShieldComponent>("%ShieldComponent");
            if (shield != null) return shield;
            parent = parent.GetParent();
        }

        return null;
    }
}
