using Godot;
using System;
using System.Runtime.Serialization;


public partial class BlockPart : Node2D {
    [Export] public BlockPartDef PartDefinition { get; set; }
    private Area2D _detectingArea = new();
    private CollisionShape2D _detectingCollisionShape = new();
    private Sprite2D _sprite2D = new();

    [Signal]
    public delegate void PressedEventHandler(Node n);

    [Signal]
    public delegate void ReleasedEventHandler(Node n);

    public override void _Ready() {
        var shape2D = new RectangleShape2D();
        shape2D.SetSize(new Vector2(Global.GridSize, Global.GridSize));
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

        Position = PartDefinition.PartialPosition * Global.GridSize;
        SetProcessInput(true);
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