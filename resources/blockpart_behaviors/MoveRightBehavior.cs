#region

using Godot;

#endregion

[GlobalClass]
public partial class MoveRightBehavior : BlockPartBehavior {
    public override void Execute(Block block, BlockPart part) {
        GD.Print("Executing MoveRightBehavior");
    }
}