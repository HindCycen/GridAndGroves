#region

using System.Collections.Generic;
using Godot;

#endregion

public partial class StatIcon : Control {
    private Label _countLabel;
    private Stat _stat;
    private TooltipComponent _tooltipComponent;

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
        iconRect.MouseFilter = MouseFilterEnum.Ignore;
        AddChild(iconRect);

        _countLabel = new Label();
        _countLabel.Text = stat.CurrentValue.ToString();
        _countLabel.HorizontalAlignment = HorizontalAlignment.Right;
        _countLabel.VerticalAlignment = VerticalAlignment.Bottom;
        _countLabel.Size = new Vector2(iconSize, iconSize);
        _countLabel.Position = Vector2.Zero;
        _countLabel.MouseFilter = MouseFilterEnum.Ignore;
        _countLabel.AddThemeColorOverride("font_color", Colors.White);
        AddChild(_countLabel);

        _tooltipComponent = new TooltipComponent();
        AddChild(_tooltipComponent);

        MouseEntered += OnMouseEntered;
        MouseExited += OnMouseExited;

        stat.ValueChanged += OnValueChanged;
    }

    private void OnMouseEntered() {
        if (_stat?.Definition == null) return;
        var placeholders = new Dictionary<string, string> {
            { "N", _stat.CurrentValue.ToString() }
        };
        var text = "";
        if (!string.IsNullOrEmpty(_stat.Definition.StatName)) {
            text = $"{_stat.Definition.StatName}";
        }
        if (!string.IsNullOrEmpty(_stat.Definition.Description)) {
            text += $"\n{_stat.Definition.Description}";
        }
        text = _tooltipComponent.ProcessText(text, placeholders);
        _tooltipComponent.Show(GlobalPosition, text);
    }

    private void OnMouseExited() {
        _tooltipComponent.Hide();
    }

    private void OnValueChanged(int current, int max) {
        _countLabel.Text = current.ToString();
    }

    public void Detach() {
        if (_stat != null) {
            _stat.ValueChanged -= OnValueChanged;
        }
        MouseEntered -= OnMouseEntered;
        MouseExited -= OnMouseExited;
    }
}