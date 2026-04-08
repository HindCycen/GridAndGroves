#region

using Godot;
using System.Collections.Generic;

#endregion

public partial class BlockPilesHere : Node2D {
    [Export] public PileComponent DiscardedPile;
    [Export] public PileComponent DrawPile;
    [Export] public Player Player;
    [Export] public PileComponent ShowingPile;
    [Export] public PileComponent PlacedPile;

    private const float ShowingPileBaseX = 1008f;
    private const float ShowingPileBaseY = 480f;
    private readonly List<Vector2I> _occupiedPositions = [];
    private BattleTime _battleTime;

    public override void _Ready() {
        _battleTime = GetTree().Root.GetNode<BattleTime>("BattleTime");
        foreach (var b in Player.GetNode<PileComponent>("%PlayerPile").Pile) {
            DrawPile.AddBlock(Glob.CreateBlock(b.Definition));
        }

        ShowingPile.ChildEnteredTree += OnShowingPileChildAdded;
        _battleTime.TurnEnded += DiscardBlocks;
    }

    private void OnShowingPileChildAdded(Node node) {
        if (node is not Block block) {
            return;
        }

        block.Placed += OnBlockPlaced;
        var position = FindAvailablePosition(block);
        block.Position = position;
    }

    private Vector2 FindAvailablePosition(Block block) {
        var partCount = block.Definition.PartDefinitions.Length;
        var gridCols = (int) System.Math.Ceiling(System.Math.Sqrt(partCount));
        var gridRows = (int) System.Math.Ceiling((double) partCount / gridCols);

        for (var row = 0; row < 100; row++) {
            for (var col = 0; col < 100; col++) {
                var basePos = new Vector2(ShowingPileBaseX + col * Glob.GridSize * gridCols,
                    ShowingPileBaseY + row * Glob.GridSize * gridRows);

                if (IsPositionAvailable(basePos, gridCols, gridRows)) {
                    MarkPositionOccupied(basePos, gridCols, gridRows);
                    return basePos;
                }
            }
        }

        GD.PrintErr("No available position found for block");
        return new Vector2(ShowingPileBaseX, ShowingPileBaseY);
    }

    private bool IsPositionAvailable(Vector2 basePos, int cols, int rows) {
        for (var row = 0; row < rows; row++) {
            for (var col = 0; col < cols; col++) {
                var pos = new Vector2I(
                    (int) ((basePos.X + col * Glob.GridSize - ShowingPileBaseX) / Glob.GridSize),
                    (int) ((basePos.Y + row * Glob.GridSize - ShowingPileBaseY) / Glob.GridSize)
                );

                if (_occupiedPositions.Contains(pos)) {
                    return false;
                }
            }
        }

        return true;
    }

    private void MarkPositionOccupied(Vector2 basePos, int cols, int rows) {
        for (var row = 0; row < rows; row++) {
            for (var col = 0; col < cols; col++) {
                var pos = new Vector2I(
                    (int) ((basePos.X + col * Glob.GridSize - ShowingPileBaseX) / Glob.GridSize),
                    (int) ((basePos.Y + row * Glob.GridSize - ShowingPileBaseY) / Glob.GridSize)
                );

                _occupiedPositions.Add(pos);
            }
        }
    }

    // 从DrawPile中随机取出一个Block放入ShowingPile中
    // 请确保DrawPle中有东西
    private (int, int) ShowOneBlock() {
        var b = DrawPile.GetRandomBlockReference();
        ShowingPile.AddBlock(b);
        DrawPile.RemoveBlock(b);
        ShowingPile.AddChild(b);
        return (DrawPile.Count, ShowingPile.Count);
    }

    private void OnBlockPlaced(Block block) {
        block.Placed -= OnBlockPlaced;
        if (GetChildren().Contains(block)) {
            RemoveChild(block);
        }
        PlacedPile.AddBlock(block);
    }

    private void DiscardBlocks() {
        foreach (var n in GetTree().GetNodesInGroup("Blocks")) {
            if (n is not Block b || b.GetParent() is not PileComponent pc) {
                continue;
            }

            pc.RemoveChild(b);
            pc.RemoveBlock(b);
            DiscardedPile.AddBlock(b);
        }
    }
}