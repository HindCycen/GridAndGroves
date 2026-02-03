using Godot;
using System;

public partial class Battle : Node2D {
    [Export] private BlockDef[] _availableBlockDefs;

    private enum BlockNames {
        ExampleBlock,
        ExampleMovingRight,
    }

    public override void _Ready() {
        Global.InitRng();
        Global.InitGrids();
        GetNode<BlockFactory>("BlockFactory").CreateBlock(_availableBlockDefs[(int) BlockNames.ExampleBlock], new Vector2(100, 100), this);
        GetNode<BlockFactory>("BlockFactory").CreateBlock(_availableBlockDefs[(int) BlockNames.ExampleMovingRight], new Vector2(300, 100), this);
    }
}
