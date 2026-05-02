#region

using System.Collections.Generic;
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
    private TooltipComponent _tooltipComponent;
    [Export] public BlockPartDef PartDefinition { get; set; }

    public int Damage { get; set; }
    public int Shield { get; set; }
    public int MagicNum { get; set; }

    public override void _Ready() {
        var shape2D = new RectangleShape2D();
        shape2D.SetSize(new Vector2(96, 96));
        _detectingCollisionShape.Shape = shape2D;
        if (PartDefinition.SpriteTexture != null) {
            _sprite2D.SetTexture(PartDefinition.SpriteTexture);
        }

        _detectingArea.AddChild(_detectingCollisionShape);
        _detectingArea.AddChild(_sprite2D);
        AddChild(_detectingArea);

        _detectingArea.InputEvent += (_, @event, _) => {
            if (@event is not InputEventMouseButton { ButtonIndex: MouseButton.Left } mouseButton) {
                return;
            }

            if (mouseButton.Pressed) {
                EmitSignalPressed(this);
            }
            else {
                EmitSignalReleased(this);
            }
        };

        _detectingArea.MouseEntered += OnMouseEntered;
        _detectingArea.MouseExited += OnMouseExited;

        _tooltipComponent = new TooltipComponent();
        AddChild(_tooltipComponent);

        Damage = PartDefinition.BaseDamage;
        Shield = PartDefinition.BaseShield;
        MagicNum = PartDefinition.BaseMagicNum;

        Position = PartDefinition.PartialPosition * 96;
        SetProcessInput(true);
    }

    private void OnMouseEntered() {
        if (GetParent() is not Block block || block.Definition == null || block.IsPressed) {
            return;
        }

        var text = block.Definition.BlockName;
        if (!string.IsNullOrEmpty(block.Definition.Description)) {
            text += "\n" + block.Definition.Description;
        }

        if (!string.IsNullOrEmpty(PartDefinition.Description)) {
            text += "\n" + PartDefinition.Description;
        }

        if (string.IsNullOrEmpty(text)) {
            return;
        }

        var placeholders = new Dictionary<string, string> {
            { "S", Shield.ToString() },
            { "D", Damage.ToString() },
            { "M", MagicNum.ToString() }
        };

        text = _tooltipComponent.ProcessText(text, placeholders);
        _tooltipComponent.Show(GlobalPosition, text);
    }

    private void OnMouseExited() {
        _tooltipComponent.Hide();
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