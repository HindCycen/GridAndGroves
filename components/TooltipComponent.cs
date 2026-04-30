#region

using System.Collections.Generic;
using System.Text.RegularExpressions;
using Godot;

#endregion

public partial class TooltipComponent : Node {
    private static readonly Dictionary<string, string> ColorMap = new() {
        { "R", "red" }, { "G", "green" }, { "B", "blue" }, { "Y", "yellow" }
    };

    private Node _tooltip;
    [Export] public int CanvasLayerOrder = 128;
    [Export] public int MaxWidth = 260;
    [Export] public int PaddingX = 12;
    [Export] public int PaddingY = 8;

    public void Show(Vector2 globalPosition, string richText) {
        Hide();

        var label = new RichTextLabel();
        label.BbcodeEnabled = true;
        label.MouseFilter = Control.MouseFilterEnum.Ignore;
        label.AutowrapMode = TextServer.AutowrapMode.WordSmart;
        label.Size = new Vector2(MaxWidth, 200);

        var panel = new Panel();
        panel.MouseFilter = Control.MouseFilterEnum.Ignore;
        panel.Size = new Vector2(MaxWidth + PaddingX * 2, 216);
        panel.AddChild(label);

        var layer = new CanvasLayer();
        layer.Layer = CanvasLayerOrder;
        GetViewport()?.AddChild(layer);
        layer.AddChild(panel);
        _tooltip = layer;

        Callable.From(() => {
            if (_tooltip != layer) {
                return;
            }

            label.Position = new Vector2(PaddingX, PaddingY);
            label.Text = richText;

            var size = label.GetMinimumSize();
            if (size.Y > 0) {
                var panelH = size.Y + PaddingY * 2;
                panel.Size = new Vector2(panel.Size.X, panelH);
            }

            panel.Position = new Vector2(
                globalPosition.X,
                globalPosition.Y - panel.Size.Y - 5
            );
        }).CallDeferred();
    }

    public void Hide() {
        if (_tooltip != null) {
            _tooltip.QueueFree();
            _tooltip = null;
        }
    }

    public string ProcessText(string input, Dictionary<string, string> placeholders = null) {
        if (placeholders != null) {
            foreach (var kvp in placeholders) {
                input = input.Replace($"%{kvp.Key}%", kvp.Value);
            }
        }

        input = Regex.Replace(input, @"\[([RGBY])\]\{([^}]*)\}", m => {
            var color = ColorMap.TryGetValue(m.Groups[1].Value, out var c) ? c : "white";
            return $"[color={color}]{m.Groups[2].Value}[/color]";
        });

        return input;
    }

    public override void _ExitTree() {
        Hide();
    }
}