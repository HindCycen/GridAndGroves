#region

using System.Linq;
using Godot;

#endregion

/// <summary>
///     施加 Growing 状态：添加状态、从牌组移除 GrowingBlock、销毁场上该方块。
///     逻辑不可拆分，使用 CallbackAction 包装。
/// </summary>
[GlobalClass]
public partial class GiveGrowingStatBehavior : BlockPartBehavior {
    public override AbstractAction CreateAction(Block block, BlockPart part) {
        return new CallbackAction(() => {
            var tree = block.GetTree();
            if (tree == null) {
                return;
            }

            var players = tree.GetNodesInGroup("Players");
            foreach (var node in players) {
                if (node is not Node2D player) {
                    continue;
                }

                var renderingComponent = player.GetNode<RenderingComponent>("RenderingComponent");
                var statsComponent = renderingComponent.StatsComponent;

                if (!statsComponent.HasStatus("Growing")) {
                    var statDef = GD.Load<StatDef>("res://resources/stat_defs/Growing.tres");
                    if (statDef != null) {
                        var stat = new Stat { Definition = statDef };
                        statsComponent.AddStatus(stat);
                        stat.AddValue(statDef.MaxValue);
                    }
                }

                var playerPile = player.GetNode<PileComponent>("%PlayerPile");
                var growingBlock = playerPile.Pile
                    .FirstOrDefault(b => b.Definition?.BlockName == "Growing");
                if (growingBlock != null) {
                    playerPile.RemoveBlock(growingBlock);
                    if (IsInstanceValid(growingBlock) && growingBlock.GetParent() != null) {
                        growingBlock.GetParent().RemoveChild(growingBlock);
                    }

                    growingBlock.QueueFree();
                }
            }

            // 销毁场上此 Block 并释放网格
            foreach (var p in block.GetParts()) {
                var gridPoint = Glob.FindNearestGridPoint(p.GlobalPosition);
                var coords = Glob.GetGridCoords(gridPoint);
                if (coords.X >= 0 && coords.Y >= 0) {
                    Glob.RestoreGridState(coords.X, coords.Y);
                }
            }

            var blockPilesHere = block.GetParent() as BlockPilesHere;
            blockPilesHere?.PlacedPile.RemoveBlock(block);
            if (IsInstanceValid(block) && block.GetParent() != null) {
                block.GetParent().RemoveChild(block);
            }

            block.QueueFree();
        }, Glob.ActionType.ApplyStatus);
    }
}