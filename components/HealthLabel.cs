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
        if (_shieldComponent != null) {
            _shieldComponent.ShieldChanged += (_, _) =>
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
}