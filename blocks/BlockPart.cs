#region

using System.Text.RegularExpressions;
using Godot;

#endregion

public partial class BlockPart : Node2D {
    [Signal]
    public delegate void PressedEventHandler(Node n);

    [Signal]
    public delegate void ReleasedEventHandler(Node n);

    private Area2D _detectingArea = new();
    private CollisionShape2D _detectingCollisionShape = new();
    private Sprite2D _sprite2D = new();
    private Node _tooltip;
    [Export] public BlockPartDef PartDefinition { get; set; }

    public override void _Ready() {
        var shape2D = new RectangleShape2D();
        shape2D.SetSize(new Vector2(Glob.GridSize, Glob.GridSize));
        _detectingCollisionShape.Shape = shape2D;
        if (PartDefinition.SpriteTexture != null) {
            _sprite2D.SetTexture(PartDefinition.SpriteTexture);
        }

        _detectingArea.AddChild(_detectingCollisionShape);
        _detectingArea.AddChild(_sprite2D);
        AddChild(_detectingArea);

        _detectingArea.InputEvent += (_, @event, _) => {
            if (@event is InputEventMouseButton mouseButton &&
                mouseButton.ButtonIndex == MouseButton.Left) {
                if (mouseButton.Pressed) {
                    EmitSignalPressed(this);
                }
                else {
                    EmitSignalReleased(this);
                }
            }
        };

        _detectingArea.MouseEntered += OnMouseEntered;
        _detectingArea.MouseExited += OnMouseExited;

        Position = PartDefinition.PartialPosition * Glob.GridSize;
        SetProcessInput(true);
    }

    public override void _ExitTree() {
        HideTooltip();
    }

    private void OnMouseEntered() {
        if (GetParent() is Block block && block.Definition != null && !block.IsPressed) {
            ShowTooltip(block);
        }
    }

    private void OnMouseExited() {
        HideTooltip();
    }

    private void ShowTooltip(Block block) {
        var text = block.Definition.BlockName;
        if (!string.IsNullOrEmpty(block.Definition.Description))
            text += "\n" + block.Definition.Description;
        if (!string.IsNullOrEmpty(PartDefinition.Description))
            text += "\n" + PartDefinition.Description;

        if (string.IsNullOrEmpty(text)) return;

        text = ProcessText(text);

        var label = new RichTextLabel();
        label.BbcodeEnabled = true;
        label.MouseFilter = Control.MouseFilterEnum.Ignore;
        label.AutowrapMode = TextServer.AutowrapMode.WordSmart;
        label.Size = new Vector2(260, 200);

        var panel = new Panel();
        panel.MouseFilter = Control.MouseFilterEnum.Ignore;
        panel.Size = new Vector2(284, 216);
        panel.AddChild(label);

        var layer = new CanvasLayer();
        layer.Layer = 128;
        GetViewport().AddChild(layer);
        layer.AddChild(panel);
        _tooltip = layer;

        Callable.From(() => {
            if (_tooltip != layer) return;
            label.Position = new Vector2(12, 8);
            label.Text = text;
            panel.Position = GlobalPosition + new Vector2(Glob.GridSize * 0.5f, -panel.Size.Y - 5);
        }).CallDeferred();
    }

    private void HideTooltip() {
        if (_tooltip != null) {
            _tooltip.QueueFree();
            _tooltip = null;
        }
    }

    private string ProcessText(string text) {
        text = text.Replace("%B%", PartDefinition.Block.ToString())
                   .Replace("%D%", PartDefinition.Damage.ToString())
                   .Replace("%M%", PartDefinition.MagicNum.ToString());

        text = Regex.Replace(text, @"\[([RGBY])\]\{([^}]*)\}", m => {
            var color = m.Groups[1].Value switch {
                "R" => "red",
                "G" => "green",
                "B" => "blue",
                "Y" => "yellow",
                _ => "white"
            };
            return $"[color={color}]{m.Groups[2].Value}[/color]";
        });

        return text;
    }

    public Vector2I Execute(Block owner) {
        if (PartDefinition.Behaviors == null) {
            return Vector2I.Down;
        }

        foreach (var behavior in PartDefinition.Behaviors) {
            behavior?.Execute(owner, this);
        }

        return PartDefinition.MovingDirection;
    }
}