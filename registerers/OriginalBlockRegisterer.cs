#region

using Godot;

#endregion

[BlockRegisterer]
public class OriginalBlockRegisterer : AbstractBlockRegisterer {
    public override void Register() {
        Glob.SubscribeBlockDef(GD.Load<BlockDef>("res://resources/blockdefs/ExampleBlock.tres"));
        Glob.SubscribeBlockDef(GD.Load<BlockDef>("res://resources/blockdefs/ExampleMoveRight.tres"));
        Glob.SubscribeBlockDef(GD.Load<BlockDef>("res://resources/blockdefs/DamageBlock.tres"));
        Glob.SubscribeBlockDef(GD.Load<BlockDef>("res://resources/blockdefs/EnemyAttackBlock.tres"));
        Glob.SubscribeBlockDef(GD.Load<BlockDef>("res://resources/blockdefs/GrowingBlock.tres"));
    }
}