#region

using System.Collections.Generic;
using System.Linq;
using Godot;

#endregion

public partial class BlockPilesHere : Node2D {
    [Export] public PileComponent DiscardedPile;
    [Export] public PileComponent DrawPile;
    [Export] public Player Player;
    [Export] public PileComponent ShowingPile;
    [Export] public PileComponent PlacedPile;

    private const float ShowingPileBaseX = 0f;
    private const float ShowingPileBaseY = 0f;
    private readonly List<Vector2I> _occupiedPositions = [];

    public override void _Ready() {
        // DrawPile 的初始化由 Battle.cs 在 InitializePlayerDeck 后调用
        ShowingPile.ChildEnteredTree += OnShowingPileChildAdded;
    }

    /// <summary>
    /// 从玩家牌堆初始化抽牌堆（由 Battle.cs 在合适的时机调用）
    /// </summary>
    public void InitializeDrawPile() {
        foreach (var b in Player.GetNode<PileComponent>("%PlayerPile").Pile) {
            DrawPile.AddBlock(Glob.CreateBlock(b.Definition));
        }
        GD.Print($"抽牌堆初始化完成，共 {DrawPile.Count} 张牌");
    }

    /// <summary>
    /// 从抽牌堆中抽取 count 张牌到展示区
    /// </summary>
    public void DrawCards(int count) {
        for (var i = 0; i < count; i++) {
            if (DrawPile.Count == 0) {
                // 如果抽牌堆空了，从弃牌堆洗牌回来
                ReshuffleDiscardToDraw();
                if (DrawPile.Count == 0) break;
            }
            ShowOneBlock();
        }
    }

    /// <summary>
    /// 清空当前回合玩家的展示区和已放置区，将玩家方块移入弃牌堆
    /// </summary>
    public void ClearPlayerRound() {
        // 清空展示区
        var showingBlocks = ShowingPile.Pile.ToList();
        foreach (var block in showingBlocks) {
            if (IsInstanceValid(block) && block.GetParent() == ShowingPile) {
                ShowingPile.RemoveChild(block);
            }
            ShowingPile.RemoveBlock(block);
            if (!block.IsPlaced) {
                block.QueueFree();
            }
        }

        // 清空已放置区中属于玩家的方块
        var placedBlocks = PlacedPile.Pile.Where(b => b.Faction == Block.BlockFaction.Player).ToList();
        foreach (var block in placedBlocks) {
            PlacedPile.RemoveBlock(block);
            foreach (var part in block.GetParts()) {
                var gridPos = Glob.FindNearestGridPoint(part.GlobalPosition);
                var coords = Glob.GetGridCoords(gridPos);
                if (coords.X >= 0 && coords.Y >= 0) {
                    Glob.SetGridState(coords.X, coords.Y, Glob.GridState.Free);
                }
            }
            if (block.GetParent() != null && IsInstanceValid(block.GetParent())) {
                block.GetParent().RemoveChild(block);
            }
            DiscardedPile.AddBlock(block);
        }

        // 清空占用位置记录
        _occupiedPositions.Clear();
    }

    private void ReshuffleDiscardToDraw() {
        GD.Print("抽牌堆空了，洗回弃牌堆！");
        var discarded = DiscardedPile.Pile.ToList();
        foreach (var block in discarded) {
            DiscardedPile.RemoveBlock(block);
            DrawPile.AddBlock(block);
        }
    }

    private void OnShowingPileChildAdded(Node node) {
        if (node is not Block block) {
            return;
        }

        // 重置放置状态，确保从弃牌堆洗回的方块可以重新拖动和放置
        block.IsPlaced = false;

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

    /// <summary>
    /// 从抽牌堆中随机取出一张牌放入展示区
    /// </summary>
    private void ShowOneBlock() {
        if (DrawPile.Count == 0) return;

        var b = DrawPile.GetRandomBlockReference();
        ShowingPile.AddBlock(b);
        DrawPile.RemoveBlock(b);
        ShowingPile.AddChild(b);
    }

    private void OnBlockPlaced(Block block) {
        block.Placed -= OnBlockPlaced;

        // 保存全局位置，重定父级后恢复
        var globalPos = block.GlobalPosition;

        if (block.GetParent() != null && IsInstanceValid(block.GetParent())) {
            block.GetParent().RemoveChild(block);
        }
        AddChild(block);
        block.GlobalPosition = globalPos;

        // 从展示区移除
        if (ShowingPile.Pile.Contains(block)) {
            ShowingPile.RemoveBlock(block);
        }
        PlacedPile.AddBlock(block);

        // 放一补一：放置后自动从抽牌堆补一张到展示区
        DrawCards(1);
    }
}
