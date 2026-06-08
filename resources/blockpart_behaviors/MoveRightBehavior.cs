#region

using Godot;

#endregion

/// <summary>
///     方向修改行为——方向由 MovingDirection 同步修改，行为本身无需产生 Action。
/// </summary>
[GlobalClass]
public partial class MoveRightBehavior : BlockPartBehavior {
    public override AbstractGameAction CreateAction(Block block, BlockPart part) {
        // 方向修改由 Bot.EnqueueBlockActionsAt() 同步处理（MovingDirection）
        // 本行为不需要产生任何动作
        return null;
    }
}