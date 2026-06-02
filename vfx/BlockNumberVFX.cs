#region

using Godot;

#endregion

/// <summary>
///     浮动格挡数字效果。用法同 DamageNumberVFX，但颜色为蓝/绿色。
/// </summary>
public partial class BlockNumberVFX : Node2D {
    private readonly Label _label;
    private float _alpha = 1.0f;
    private Vector2 _velocity;

    public BlockNumberVFX(Vector2 position, int amount, Color? color = null) {
        GlobalPosition = position;
        _velocity = new Vector2(0, -50);
        ZIndex = 200;

        _label = new Label {
            Text = amount.ToString(),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            MouseFilter = Control.MouseFilterEnum.Ignore
        };
        _label.AddThemeFontSizeOverride("font_size", 32);
        _label.AddThemeColorOverride("font_color", color ?? Colors.CornflowerBlue);
        _label.SetSize(new Vector2(80, 40));
        _label.Position = new Vector2(-40, -20);
        AddChild(_label);
    }

    public override void _Process(double delta) {
        var dt = (float) delta;
        GlobalPosition += _velocity * dt;
        _alpha -= dt * 1.5f;
        Modulate = new Color(1, 1, 1, Mathf.Max(0, _alpha));
        if (_alpha <= 0) {
            QueueFree();
        }
    }
}