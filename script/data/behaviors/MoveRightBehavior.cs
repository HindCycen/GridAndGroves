using Godot;
using System;

[GlobalClass]
public partial class MoveRightBehavior : BlockPartBehavior {
    public override void Execute(Block owner, BlockPart part) {
        GD.Print("Executing MoveRightBehavior");
    }
}
