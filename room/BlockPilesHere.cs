#region

using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

#endregion

public partial class BlockPilesHere : Node2D {
    private const float ShowingPileBaseX = 0f;
    private const float ShowingPileBaseY = 0f;
    private const int MaxShowingPileColumns = 4;
    private const int CellSize = 96;
    private readonly Dictionary<Block, Vector2> _blockLayoutPositions = [];
    private int _pendingDraws;
    [Export] public PileComponent DiscardedPile;
    [Export] public PileComponent DrawPile;
    [Export] public PileComponent PlacedPile;
    [Export] public Player Player;
    [Export] public PileComponent ShowingPile;

    public override void _Ready() {
        // DrawPile 的初始化由 BattleRoom.cs 在 InitializePlayerDeck 后调用
        ShowingPile.ChildEnteredTree += OnShowingPileChildAdded;
    }

    /// <summary>
    ///     从玩家牌堆初始化抽牌堆（由 BattleRoom.cs 在合适的时机调用）
    /// </summary>
    public void InitializeDrawPile() {
        foreach (var b in Player.GetNode<PileComponent>("%PlayerPile").Pile) {
            DrawPile.AddBlock(Glob.CreateBlock(b.Definition));
        }

        GameLog.Debug($"抽牌堆初始化完成，共 {DrawPile.Count} 张牌");
    }

    /// <summary>
    ///     从抽牌堆中抽取 count 张牌到展示区。
    ///     使用待办计数器而非布尔锁：如果正在抽牌过程中又被调用，
    ///     将请求排队，等当前批次处理完再继续，不会丢牌。
    /// </summary>
    public void DrawCards(int count) {
        _pendingDraws += count;
        if (_pendingDraws > count) {
            // 已经在抽牌中，本次请求已计入 _pendingDraws，稍后处理
            return;
        }

        ProcessPendingDraws();
    }

    private void ProcessPendingDraws() {
        while (_pendingDraws > 0) {
            _pendingDraws--;

            if (DrawPile.Count == 0) {
                ReshuffleDiscardToDraw();
                if (DrawPile.Count == 0) {
                    _pendingDraws = 0;
                    break;
                }
            }

            ShowOneBlock();
        }
    }

    /// <summary>
    ///     清空当前回合玩家的展示区和已放置区，将玩家方块移入弃牌堆
    /// </summary>
    public void ClearPlayerRound() {
        ClearShowingPileBlocks();
        ClearPlacedPlayerBlocks();
        _blockLayoutPositions.Clear();
    }

    private void ClearShowingPileBlocks() {
        var showingBlocks = ShowingPile.Pile.ToList();
        foreach (var block in showingBlocks) {
            block.Placed -= OnBlockPlaced;
            block.LeftGrid -= OnBlockLeftGrid;
            UnparentBlock(block, ShowingPile);
            ShowingPile.RemoveBlock(block);
            if (!block.IsPlaced) {
                DiscardedPile.AddBlock(block);
            }
        }
    }

    private void ClearPlacedPlayerBlocks() {
        var placedBlocks = PlacedPile.Pile
            .Where(b => b.Faction == Block.BlockFaction.Player).ToList();
        foreach (var block in placedBlocks) {
            // 检查 Block 是否有任何 Part 声明了 PreventsClear
            if (block.GetParts().Any(p =>
                    p.PartDefinition?.Behaviors?.Any(bh => bh.PreventsClear) == true)) {
                GameLog.Debug($"Block {block.Definition?.BlockName} 声明了 PreventsClear，保留在网格上");
                continue;
            }

            block.Placed -= OnBlockPlaced;
            block.LeftGrid -= OnBlockLeftGrid;
            PlacedPile.RemoveBlock(block);
            FreeBlockGridCells(block);
            UnparentBlock(block, null);
            DiscardedPile.AddBlock(block);
        }
    }

    private static void UnparentBlock(Block block, Node expectedParent) {
        if (!IsInstanceValid(block) || block.GetParent() == null) {
            return;
        }

        if (expectedParent != null && block.GetParent() != expectedParent) {
            return;
        }

        block.GetParent().RemoveChild(block);
    }

    private static void FreeBlockGridCells(Block block) {
        foreach (var part in block.GetParts()) {
            var gridPos = Glob.FindNearestGridPoint(part.GlobalPosition);
            var coords = Glob.GetGridCoords(gridPos);
            if (coords.X >= 0 && coords.Y >= 0) {
                Glob.RestoreGridState(coords.X, coords.Y);
            }
        }
    }

    private void ReshuffleDiscardToDraw() {
        GameLog.Debug("抽牌堆空了，洗回弃牌堆！");
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

        block.Placed -= OnBlockPlaced;
        block.Placed += OnBlockPlaced;
        block.LeftGrid -= OnBlockLeftGrid;
        block.LeftGrid += OnBlockLeftGrid;
        var position = FindAvailablePosition(block);
        _blockLayoutPositions[block] = position;
        block.Position = position;
        block.OriginalPos = block.GlobalPosition;
    }

    private Vector2 FindAvailablePosition(Block block) {
        if (block == null) {
            return new Vector2(ShowingPileBaseX, ShowingPileBaseY);
        }

        var partCount = block.Definition.PartDefinitions.Length;
        var gridCols = (int)Math.Ceiling(Math.Sqrt(partCount));
        var gridRows = (int)Math.Ceiling((double)partCount / gridCols);
        var occupied = CollectOccupiedCells(block);

        for (var row = 0; row < 100; row++) {
            for (var col = 0; col < MaxShowingPileColumns; col++) {
                var basePos = new Vector2(ShowingPileBaseX + col * CellSize * gridCols,
                    ShowingPileBaseY + row * CellSize * gridRows);
                if (!IsCellOccupied(basePos, gridRows, gridCols, occupied)) {
                    return basePos;
                }
            }
        }

        GameLog.Err("No available position found for block");
        return new Vector2(ShowingPileBaseX, ShowingPileBaseY);
    }

    private HashSet<Vector2I> CollectOccupiedCells(Block excludeBlock) {
        var occupied = new HashSet<Vector2I>();
        foreach (var kv in _blockLayoutPositions) {
            if (kv.Key == excludeBlock) {
                continue;
            }

            var otherPartCount = kv.Key.Definition.PartDefinitions.Length;
            var otherCols = (int)Math.Ceiling(Math.Sqrt(otherPartCount));
            var otherRows = (int)Math.Ceiling((double)otherPartCount / otherCols);

            for (var r = 0; r < otherRows; r++) {
                for (var c = 0; c < otherCols; c++) {
                    var p = new Vector2I(
                        (int)((kv.Value.X + c * CellSize - ShowingPileBaseX) / CellSize),
                        (int)((kv.Value.Y + r * CellSize - ShowingPileBaseY) / CellSize)
                    );
                    occupied.Add(p);
                }
            }
        }

        return occupied;
    }

    private bool IsCellOccupied(Vector2 basePos, int gridRows, int gridCols,
        HashSet<Vector2I> occupied) {
        for (var r = 0; r < gridRows; r++) {
            for (var c = 0; c < gridCols; c++) {
                var p = new Vector2I(
                    (int)((basePos.X + c * CellSize - ShowingPileBaseX) / CellSize),
                    (int)((basePos.Y + r * CellSize - ShowingPileBaseY) / CellSize)
                );
                if (occupied.Contains(p)) {
                    return true;
                }
            }
        }

        return false;
    }

    /// <summary>
    ///     从抽牌堆中随机取出一张牌放入展示区
    /// </summary>
    private void ShowOneBlock() {
        if (DrawPile.Count == 0) {
            return;
        }

        var b = DrawPile.GetRandomBlockReference();
        ShowingPile.AddBlock(b);
        DrawPile.RemoveBlock(b);
        ShowingPile.AddChild(b);
    }

    private void OnBlockLeftGrid(Block block) {
        block.IsPlaced = false;
        PlacedPile.RemoveBlock(block);

        if (block.GetParent() != null && IsInstanceValid(block.GetParent())) {
            block.GetParent().RemoveChild(block);
        }

        ShowingPile.AddBlock(block);
        ShowingPile.AddChild(block);
    }

    private void OnBlockPlaced(Block block) {
        var isNewPlacement = ShowingPile.Pile.Contains(block);

        if (isNewPlacement) {
            // 首次放置：从展示区移至已放置区，补一张牌
            var globalPos = block.GlobalPosition;

            _blockLayoutPositions.Remove(block);

            if (block.GetParent() != null && IsInstanceValid(block.GetParent())) {
                block.GetParent().RemoveChild(block);
            }

            AddChild(block);
            block.GlobalPosition = globalPos;

            ShowingPile.RemoveBlock(block);
            PlacedPile.AddBlock(block);

            // 放一补一
            DrawCards(1);
        }
        // 重新放置（从棋盘抬起后再次放下）：已在 PlacedPile，无需额外操作
    }
}