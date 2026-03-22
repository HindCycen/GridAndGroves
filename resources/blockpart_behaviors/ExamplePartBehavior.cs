#region

using Godot;

#endregion

[GlobalClass]
public partial class ExamplePartBehavior : BlockPartBehavior {
    public override void Execute(Block block, BlockPart part) {
        GD.Print("ExamplePartBehavior executed!" + part.PartDefinition.PartId);
    }
}