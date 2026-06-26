#region

using System.Linq;
using Godot;

#endregion

/// <summary>
///     通用"给玩家添加 Stat"行为。
///     Bot 经过此 Part 时，为玩家添加指定的 Stat，并将此 Block 从卡组中永久移除。
///
///     用法（遗物/药水通用）：
///     - 遗物效果：StatDef.RemoveOnBattleEnd = false（默认，跨战斗保留）
///     - 药水效果：StatDef.RemoveOnBattleEnd = true（战斗结束自动移除）
///
///     创建新的遗物/药水只需：
///     1. 创建 StatDef.tres，配好 StatBehavior
///     2. 创建此 Behavior 的实例，引用上述 StatDef
///     3. 组装到 BlockDef 中
///     无需写新 C# 代码。
/// </summary>
[GlobalClass]
public partial class GrantPlayerStatBehavior : BlockPartBehavior {
    /// <summary>要授予的 StatDef 引用。</summary>
    [Export] public StatDef TargetStatDef;

    /// <summary>授予时的初始值/层数。</summary>
    [Export] public int InitialValue = 1;

    /// <summary>是否将此 Block 从玩家永久卡组中移除（遗物/药水均为 true）。</summary>
    [Export] public bool RemoveBlockFromDeck = true;

    /// <summary>此 Block 在 Bot 执行后是否从网格消失（默认 true）。</summary>
    [Export] public bool ShouldExhaust = true;

    /// <summary>
    ///     此 Behavior 阻止其 Block 在回合结束时被清除。
    ///     遗物/药水 block 被 Bot 触发后立即 Exhaust，不需要跨回合保留，
    ///     但触发之前如果没被 Bot 踩到，需要在回合结束时被正常清除。
    ///     保持 false 以确保回合清理正常工作。
    /// </summary>
    public override bool PreventsClear => false;

    public override AbstractGameAction CreateAction(Block block, BlockPart part) {
        if (TargetStatDef == null) {
            GameLog.Err("GrantPlayerStatBehavior: TargetStatDef 未设置！");
            return null;
        }

        var tree = block.GetTree();
        if (tree == null) return null;

        var players = tree.GetNodesInGroup("Players");
        if (players.Count == 0) return null;

        var player = players[0] as Node2D;
        if (player == null) return null;

        return new CallbackAction(() => {
            // 1. 给玩家添加 Stat
            var rendering = player.GetNode<RenderingComponent>("RenderingComponent");
            var statsComponent = rendering?.StatsComponent;
            if (statsComponent != null) {
                if (!statsComponent.HasStatus(TargetStatDef.StatName)) {
                    var stat = new Stat { Definition = TargetStatDef };
                    statsComponent.AddStatus(stat);
                    stat.AddValue(InitialValue);
                    GameLog.Debug($"GrantPlayerStatBehavior: 添加 Stat [{TargetStatDef.StatName}] = {InitialValue}");
                }
                else {
                    var existing = statsComponent.GetStatus(TargetStatDef.StatName);
                    existing?.AddValue(InitialValue);
                    GameLog.Debug($"GrantPlayerStatBehavior: 叠加 Stat [{TargetStatDef.StatName}] +{InitialValue} = {existing?.CurrentValue}");
                }
            }

            // 2. 将此 Block 从玩家永久卡组中移除
            if (RemoveBlockFromDeck && block.Definition != null) {
                var playerPile = player.GetNode<PileComponent>("%PlayerPile");
                var blockInDeck = playerPile.Pile
                    .FirstOrDefault(b => b.Definition?.BlockName == block.Definition?.BlockName);
                if (blockInDeck != null) {
                    playerPile.RemoveBlock(blockInDeck);
                    if (IsInstanceValid(blockInDeck) && blockInDeck.GetParent() != null) {
                        blockInDeck.GetParent().RemoveChild(blockInDeck);
                    }
                    blockInDeck.QueueFree();
                    GameLog.Debug($"GrantPlayerStatBehavior: 从卡组中移除 [{block.Definition.BlockName}]");
                }
            }
        }, Glob.ActionType.ApplyStatus, exhaustSourceBlock: ShouldExhaust);
    }
}
