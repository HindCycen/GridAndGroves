#region

using Godot;

#endregion

public partial class HealthLabel : Label {
    [Export] public TextureProgressBar HealthBar;
    [Export] public HealthComponent HealthComponent;

    public override void _Ready() {
        Text = $"{HealthComponent.CurrentHealth}/{HealthComponent.MaxHealth}";
        HealthComponent.HealthChanged += (c, m) => Text = $"{c}/{m}";
    }
}