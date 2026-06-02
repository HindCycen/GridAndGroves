using Godot;

/// <summary>
/// 浮动伤害数字效果。从目标位置向上飘移并淡出。
/// 使用 Godot 的 Label 节点实现，自动销毁。
/// </summary>
public partial class DamageNumberVFX : Node2D {
    private readonly Label _label;
    private Vector2 _velocity;
    private float _alpha = 1.0f;

    /// <summary>
    /// 创建一个浮动伤害数字。
    /// </summary>
    public DamageNumberVFX(Vector2 position, int amount, Color? color = null) {
        GlobalPosition = position;
        _velocity = new Vector2(0, -60); // 每秒上移 60px
        ZIndex = 200;

        _label = new Label {
            Text = amount.ToString(),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            MouseFilter = Control.MouseFilterEnum.Ignore,
        };
        _label.AddThemeFontSizeOverride("font_size", 36);
        _label.AddThemeColorOverride("font_color", color ?? Colors.Red);
        _label.SetSize(new Vector2(80, 40));
        _label.Position = new Vector2(-40, -20);
        AddChild(_label);
    }

    public override void _Process(double delta) {
        var dt = (float)delta;
        // 向上飘移
        GlobalPosition += _velocity * dt;
        // 淡出
        _alpha -= dt * 1.5f;
        Modulate = new Color(1, 1, 1, Mathf.Max(0, _alpha));

        if (_alpha <= 0) {
            QueueFree();
        }
    }
}
