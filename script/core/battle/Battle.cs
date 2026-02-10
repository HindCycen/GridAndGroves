using Godot;
using System;

public partial class Battle : Node2D {
    [Export] private BlockFactory _blockFactory;

    public override void _Ready() {
        Global.InitRng();
        Global.InitGrids();
        GetNode<BlockFactory>("BlockFactory").CreateBlock(
            _blockFactory._availableBlockDefs[(int) BlockFactory.BlockNames.ExampleBlock],
            new Vector2(100, 100),
            this);
        GetNode<BlockFactory>("BlockFactory").CreateBlock(
            _blockFactory._availableBlockDefs[(int) BlockFactory.BlockNames.ExampleMovingRight],
            new Vector2(300, 100),
            this);
    }
}
