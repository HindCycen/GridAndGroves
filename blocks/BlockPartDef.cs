#region

using Godot;

#endregion

[GlobalClass]
public partial class BlockPartDef : Resource {
    [Export] public BlockPartBehavior[] Behaviors;
    [Export] public int Block;
    [Export] public int Damage;
    [Export] public int MagicNum;
    [Export] public Vector2I MovingDirection;
    [Export] public Vector2 PartialPosition;
    [Export] public string PartId;
    [Export] public string Description;
    [Export] public Texture2D SpriteTexture;
}