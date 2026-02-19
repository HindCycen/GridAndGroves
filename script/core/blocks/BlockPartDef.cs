using Godot;
using System;

[GlobalClass]
public partial class BlockPartDef : Resource {
    [Export] public string PartId;
    [Export] public Vector2 PartialPosition;
    [Export] public Texture2D SpriteTexture;
    [Export] public BlockPartBehavior[] Behaviors;
    [Export] public Vector2I MovingDirection;
    [Export] public int Damage = 0;
    [Export] public int Block = 0;
    [Export] public int MagicNum = 0;
}