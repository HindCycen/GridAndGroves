#region

using Godot;

#endregion

/// <summary>
///     示例行为——仅用于演示和测试。
/// </summary>
[GlobalClass]
public partial class ExamplePartBehavior : BlockPartBehavior {
    public override AbstractAction CreateAction(Block block, BlockPart part) {
        GD.Print($"ExamplePartBehavior 执行: {part.PartDefinition?.PartId ?? "?"}");
        return null;
    }
}