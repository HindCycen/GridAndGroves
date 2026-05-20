using Godot;

[GlobalClass]
public partial class BigBlockBag : Resource {
    [Export] public BlockDef[] CommonBlocks;
    [Export] public BlockDef[] UncommonBlocks;
    [Export] public BlockDef[] RareBlocks;

    public BlockDef[] All => [.. CommonBlocks, .. UncommonBlocks, .. RareBlocks];
}