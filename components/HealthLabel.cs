#region

using Godot;

#endregion

public partial class HealthLabel : Label {
    [Export] private ShieldComponent _shieldComponent;
    [Export] public TextureProgressBar HealthBar;
    [Export] public HealthComponent HealthComponent;

    public override void _Ready() {
        UpdateText(HealthComponent.CurrentHealth, HealthComponent.MaxHealth);
        HealthComponent.HealthChanged += UpdateText;

        // 自动查找 ShieldComponent（如果 Export 没绑）
        var shield = _shieldComponent;
        if (shield == null) {
            shield = ResolveShieldComponent();
        }

        if (shield != null) {
            _shieldComponent = shield;
            shield.ShieldChanged += (_, _) =>
                UpdateText(HealthComponent.CurrentHealth, HealthComponent.MaxHealth);
        }
    }

    private void UpdateText(int current, int max) {
        if (_shieldComponent != null && _shieldComponent.CurrentShield > 0) {
            Text = $"{current}/{max}(+{_shieldComponent.CurrentShield})";
        }
        else {
            Text = $"{current}/{max}";
        }
    }

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
