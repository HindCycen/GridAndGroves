using Godot;
using System;

public partial class OriginalBlockRegisterer: AbstractBlockRegisterer{
    public override void Register() {
        Global.SubscribeBlockDef(GD.Load<BlockDef>("res://resources/blockdefs/ExampleBlock.tres"));
        Global.SubscribeBlockDef(GD.Load<BlockDef>("res://resources/blockdefs/ExampleMoveRight.tres"));
    }
}