#region

using Godot;

#endregion

[BlockRegisterer]
public class OriginalBlockRegisterer : AbstractBlockRegisterer {
    public override void Register() {
        Glob.SubscribeBlockDef(GD.Load<BlockDef>("res://blocks/blockdefs/ExampleBlock.tres"));
        Glob.SubscribeBlockDef(GD.Load<BlockDef>("res://blocks/blockdefs/ExampleMoveRight.tres"));
    }
}