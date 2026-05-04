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
    private readonly Dictionary<Block, Vector2> _blockLayoutPositions = [];
    private bool _isDrawingCards;
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

        GD.Print($"抽牌堆初始化完成，共 {DrawPile.Count} 张牌");
    }

    /// <summary>
    ///     从抽牌堆中抽取 count 张牌到展示区
    /// </summary>
    public void DrawCards(int count) {
        if (_isDrawingCards) return;
        if (DrawPile.Count == 0 && DiscardedPile.Count == 0) return;

        _isDrawingCards = true;
        for (var i = 0; i < count; i++) {
            if (DrawPile.Count == 0) {
                ReshuffleDiscardToDraw();
                if (DrawPile.Count == 0) {
                    break;
                }
            }

            ShowOneBlock();
        }
        _isDrawingCards = false;
    }

    /// <summary>
    ///     清空当前回合玩家的展示区和已放置区，将玩家方块移入弃牌堆
    /// </summary>
    public void ClearPlayerRound() {
        // 清空展示区 — 未放置的方块移入弃牌堆而非销毁
        var showingBlocks = ShowingPile.Pile.ToList();
        foreach (var block in showingBlocks) {
            block.Placed -= OnBlockPlaced;
            block.LeftGrid -= OnBlockLeftGrid;

            if (IsInstanceValid(block) && block.GetParent() == ShowingPile) {
                ShowingPile.RemoveChild(block);
            }

            ShowingPile.RemoveBlock(block);
            if (!block.IsPlaced) {
                DiscardedPile.AddBlock(block);
            }
        }

        // 清空已放置区中属于玩家的方块
        var placedBlocks = PlacedPile.Pile.Where(b => b.Faction == Block.BlockFaction.Player).ToList();
        foreach (var block in placedBlocks) {
            block.Placed -= OnBlockPlaced;
            block.LeftGrid -= OnBlockLeftGrid;
            PlacedPile.RemoveBlock(block);
            foreach (var part in block.GetParts()) {
                var gridPos = Glob.FindNearestGridPoint(part.GlobalPosition);
                var coords = Glob.GetGridCoords(gridPos);
                if (coords.X >= 0 && coords.Y >= 0) {
                    Glob.RestoreGridState(coords.X, coords.Y);
                }
            }

            if (block.GetParent() != null && IsInstanceValid(block.GetParent())) {
                block.GetParent().RemoveChild(block);
            }

            DiscardedPile.AddBlock(block);
        }

        // 清空占用位置记录
        _blockLayoutPositions.Clear();
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
        var partCount = block.Definition.PartDefinitions.Length;
        var gridCols = (int) Math.Ceiling(Math.Sqrt(partCount));
        var gridRows = (int) Math.Ceiling((double) partCount / gridCols);

        // 动态构建当前手牌中所有 Block 占用的格子集合
        var occupied = new HashSet<Vector2I>();
        foreach (var kv in _blockLayoutPositions) {
            if (kv.Key == block) continue;
            var otherPartCount = kv.Key.Definition.PartDefinitions.Length;
            var otherCols = (int) Math.Ceiling(Math.Sqrt(otherPartCount));
            var otherRows = (int) Math.Ceiling((double) otherPartCount / otherCols);

            for (var r = 0; r < otherRows; r++) {
                for (var c = 0; c < otherCols; c++) {
                    var p = new Vector2I(
                        (int) ((kv.Value.X + c * 96 - ShowingPileBaseX) / 96),
                        (int) ((kv.Value.Y + r * 96 - ShowingPileBaseY) / 96)
                    );
                    occupied.Add(p);
                }
            }
        }

        for (var row = 0; row < 100; row++) {
            for (var col = 0; col < MaxShowingPileColumns; col++) {
                var basePos = new Vector2(ShowingPileBaseX + col * 96 * gridCols,
                    ShowingPileBaseY + row * 96 * gridRows);

                var isFree = true;
                for (var r = 0; r < gridRows && isFree; r++) {
                    for (var c = 0; c < gridCols && isFree; c++) {
                        var p = new Vector2I(
                            (int) ((basePos.X + c * 96 - ShowingPileBaseX) / 96),
                            (int) ((basePos.Y + r * 96 - ShowingPileBaseY) / 96)
                        );
                        if (occupied.Contains(p)) isFree = false;
                    }
                }

                if (isFree) {
                    return basePos;
                }
            }
        }

        GD.PrintErr("No available position found for block");
        return new Vector2(ShowingPileBaseX, ShowingPileBaseY);
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