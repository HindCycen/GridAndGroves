/// <summary>
///     无效果行为——占位用。
/// </summary>
public partial class DoNothing : BlockPartBehavior {
    public override AbstractGameAction CreateAction(Block block, BlockPart part) {
        return null;
    }
}