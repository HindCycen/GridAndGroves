using Godot;
using System;

[GlobalClass]
public partial class EnemyTurnDef : Resource {
    [Export] public BlockDef[] AvailableBlocks;
    [Export] public int MinBlocksCount;
    [Export] public int MaxBlocksCount;
}
