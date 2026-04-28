#region

using Godot;

#endregion

public partial class StatIcon : Control {
    private Label _countLabel;
    private Stat _stat;

    public void Setup(Stat stat, int iconSize) {
        _stat = stat;

        CustomMinimumSize = new Vector2(iconSize, iconSize);
        Size = new Vector2(iconSize, iconSize);

        var iconRect = new TextureRect();
        iconRect.Texture = stat.Definition.Icon;
        iconRect.ExpandMode = TextureRect.ExpandModeEnum.FitWidth;
        iconRect.StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered;
        iconRect.Size = new Vector2(iconSize, iconSize);
        iconRect.Position = Vector2.Zero;
        iconRect.MouseFilter = MouseFilterEnum.Pass;
        AddChild(iconRect);

        _countLabel = new Label();
        _countLabel.Text = stat.CurrentValue.ToString();
        _countLabel.HorizontalAlignment = HorizontalAlignment.Right;
        _countLabel.VerticalAlignment = VerticalAlignment.Bottom;
        _countLabel.Size = new Vector2(iconSize, iconSize);
        _countLabel.Position = Vector2.Zero;
        _countLabel.MouseFilter = MouseFilterEnum.Pass;
        _countLabel.AddThemeColorOverride("font_color", Colors.White);
        AddChild(_countLabel);

        stat.ValueChanged += OnValueChanged;
    }

    private void OnValueChanged(int current, int max) {
        _countLabel.Text = current.ToString();
    }

    public void Detach() {
        if (_stat != null) {
            _stat.ValueChanged -= OnValueChanged;
        }
    }
}