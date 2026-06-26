#region

using Godot;

#endregion

/// <summary>
///     格挡行为：Bot 踩到此 Part 时为玩家添加护盾。
///     护盾值 = part.Shield（由 BlockPartDef.BaseShield 初始化）。
///     护盾在回合结束时自动清空（由 ShieldComponent.OnTurnEnded 处理）。
/// </summary>
[GlobalClass]
public partial class GrantShieldBehavior : BlockPartBehavior {
    public override AbstractGameAction CreateAction(Block block, BlockPart part) {
        var tree = block.GetTree();
        if (tree == null) return null;

        var players = tree.GetNodesInGroup("Players");
        var player = players?.Count > 0 ? players[0] as Node2D : null;
        if (player == null) return null;

        var amount = part.Shield;

        return new CallbackAction(() => {
            // %ShieldComponent 的 unique_name 只作用于 RenderingComponent.tscn 内，
            // 从 Player 根节点找不到，需递归遍历子节点
            var shieldComp = FindShieldComponent(player);
            if (shieldComp != null) {
                shieldComp.AddShield(amount);
                GameLog.Debug($"GrantShieldBehavior: 添加 {amount} 点护盾，当前 {shieldComp.CurrentShield}");
            }
            else {
                GameLog.Err("GrantShieldBehavior: 找不到 ShieldComponent！");
            }
        }, Glob.ActionType.Block);
    }

    /// <summary>
    ///     递归遍历节点树，查找 ShieldComponent。
    ///     ShieldComponent 位于 RenderingComponent 子场景内，
    ///     unique_name 不跨场景边界，所以不能用 % 语法直接从 Player 根节点查找。
    /// </summary>
    private static ShieldComponent FindShieldComponent(Node root) {
        if (root is ShieldComponent sc) {
            return sc;
        }

        foreach (var child in root.GetChildren()) {
            var found = FindShieldComponent(child);
            if (found != null) return found;
        }

        return null;
    }
}
