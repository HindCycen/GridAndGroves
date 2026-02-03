using Godot;
using System;

[GlobalClass]
public partial class ExamplePartBehavior : BlockPartBehavior {
    public override void Execute(Block owner, BlockPart part) {
        GD.Print("ExamplePartBehavior executed!" + part.PartDefinition.PartId);
    }
}
