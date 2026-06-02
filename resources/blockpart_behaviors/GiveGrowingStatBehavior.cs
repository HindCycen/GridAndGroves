using System.Linq;
using Godot;

/// <summary>
/// 施加 Growing 状态。在战斗结束时回复 12 点生命。
///
/// CreateAction 流程：
/// 1. 施加 ApplyStatusAction（Growing 状态）
/// 2. 从玩家牌组移除 GrowingBlock（CallbackAction）
/// 3. 销毁场上已放置的 Growing Block，释放网格（CallbackAction）
/// </summary>
[GlobalClass]
public partial class GiveGrowingStatBehavior : BlockPartBehavior {
    public override void Execute(Block block, BlockPart part) {
        var tree = block.GetTree();
        if (tree == null) return;

        var players = tree.GetNodesInGroup("Players");
        foreach (var node in players) {
            if (node is not Node2D player) continue;

            var renderingComponent = player.GetNode<RenderingComponent>("RenderingComponent");
            var statsComponent = renderingComponent.StatsComponent;

            if (!statsComponent.HasStatus("Growing")) {
                var statDef = GD.Load<StatDef>("res://resources/stat_defs/Growing.tres");
                if (statDef != null) {
                    var stat = new Stat { Definition = statDef };
                    statsComponent.AddStatus(stat);
                    stat.AddValue(statDef.MaxValue);
                    GD.Print("GiveGrowingStatBehavior: 添加 Growing 状态");
                }
            }

            var playerPile = player.GetNode<PileComponent>("%PlayerPile");
            var growingBlock = playerPile.Pile.FirstOrDefault(b => b.Definition?.BlockName == "Growing");
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
    }

    public override AbstractAction CreateAction(Block block, BlockPart part) {
        var tree = block.GetTree();
        if (tree == null) return base.CreateAction(block, part);

        // 用 CallbackAction 一次性完成所有操作（逻辑较复杂，不易拆分为独立 Action）
        return new CallbackAction(() => Execute(block, part), Glob.ActionType.ApplyStatus);
    }
}
