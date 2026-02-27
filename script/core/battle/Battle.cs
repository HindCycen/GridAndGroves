using Godot;
using System;

public partial class Battle : Node2D {
    public override void _Ready() {
        _initializeBlocks();
        Global.GetBlock("ExampleBlock", new Vector2(100, 100), this);
        Global.GetBlock("ExampleMovingRight", new Vector2(200, 200), this);
    }

    private void _initializeBlocks() {
        Global.SubscribeBlockDef(GD.Load<BlockDef>("res://resources/blockdefs/ExampleBlock.tres"));
        Global.SubscribeBlockDef(GD.Load<BlockDef>("res://resources/blockdefs/ExampleMovingRight.tres"));
    }
}
