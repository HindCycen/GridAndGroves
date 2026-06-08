#region

using Godot;

#endregion

/// <summary>
///     对玩家造成伤害。CreateAction 返回带 duration 的 DamageAction。
/// </summary>
[GlobalClass]
public partial class DamagePlayerBehavior : BlockPartBehavior {
    public override AbstractGameAction CreateAction(Block block, BlockPart part) {
        var tree = block.GetTree();
        var players = tree?.GetNodesInGroup("Players");
        var target = players?.Count > 0 ? players[0] as Node2D : null;

        if (target != null && part.Damage > 0) {
            return new DamageAction(block, target, part.Damage, 0.4f);
        }

        return null;
    }
}