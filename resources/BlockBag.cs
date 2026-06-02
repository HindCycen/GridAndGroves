#region

using Godot;

#endregion

[GlobalClass]
public partial class BlockBag : Resource {
    [Export] public BlockDef[] CommonBlocks;
    [Export] public BlockDef[] RareBlocks;
    [Export] public BlockDef[] UncommonBlocks;

    public BlockDef[] All => [..CommonBlocks, ..UncommonBlocks, ..RareBlocks];
}