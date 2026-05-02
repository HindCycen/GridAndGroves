#region

using Godot;

#endregion

[GlobalClass]
public partial class BlockPartDef : Resource {
    [Export] public int BaseDamage;
    [Export] public int BaseShield;
    [Export] public int BaseMagicNum;
    [Export] public BlockPartBehavior[] Behaviors;
    [Export] public string Description;
    [Export] public Vector2I MovingDirection;
    [Export] public Vector2 PartialPosition;
    [Export] public string PartId;
    [Export] public Texture2D SpriteTexture;
}