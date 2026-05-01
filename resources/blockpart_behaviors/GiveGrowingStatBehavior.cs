using System.Linq;
using Godot;

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

        foreach (var p in block.GetParts()) {
            var gridPoint = Glob.FindNearestGridPoint(p.GlobalPosition);
            var coords = Glob.GetGridCoords(gridPoint);
            if (coords.X >= 0 && coords.Y >= 0) {
                Glob.SetGridState(coords.X, coords.Y, Glob.GridState.Free);
            }
        }

        var blockPilesHere = block.GetParent() as BlockPilesHere;
        blockPilesHere?.PlacedPile.RemoveBlock(block);
        if (IsInstanceValid(block) && block.GetParent() != null) {
            block.GetParent().RemoveChild(block);
        }
        block.QueueFree();
    }
}
