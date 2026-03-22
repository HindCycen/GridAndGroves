#region

using Godot;

#endregion

[GlobalClass]
public abstract partial class BlockPartBehavior : Resource {
    public abstract void Execute(Block block, BlockPart part);
}