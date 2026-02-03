using Godot;
using System;

public partial class Main : Node2D {
    [Export] private BlockDef[] _availableBlockDefs;

    public override void _Ready() {
        Global.InitRng();
        Global.InitGrids();
        GetNode<BlockFactory>("BlockFactory").CreateBlock(_availableBlockDefs[0], new Vector2(100, 100), this);
    }
}
