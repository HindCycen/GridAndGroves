#region

using System.Linq;
using Godot;

#endregion

/// <summary>
///     Bot 在网格上巡逻，遇到 BlockPart 时将行为转为 Action 并加入队列。
///     每个 tick 流程：
///     ┌─────────────────────────────────────┐
///     │ OnPatrolTimerTimeout()              │
///     │  ① SayPreBlockExecute()  ← Phase A │
///     │  ② MoveToNextCell()                │
///     │     → EnqueueBlockActions()  ← Phase B │
///     │  ③ SayPostBlockExecute() ← Phase C │
///     └─────────────────────────────────────┘
/// </summary>
public partial class Bot : Node2D {
    private AnimatedSprite2D _animatedSprite2D;
    private BattleTime _battleTime;
    private BlockPilesHere _blockPilesHere;
    private Vector2I _currentDirection = Vector2I.Down;
    private Vector2I _currentGridPos;
    private bool _endingTurn;
    private SceneTreeTimer _patrolTimer;
    private bool _stopped;

    public override void _Ready() {
        _battleTime = GetTree().Root.GetNode<BattleTime>("BattleTime");
        _animatedSprite2D = GetNode<AnimatedSprite2D>("%AnimatedSprite2D");
        _blockPilesHere = GetParent().GetNode<BlockPilesHere>("BlockPilesHere");

        _battleTime.SayBattleStarted();
        Visible = false;
        GoToStarterPoint();
    }

    public void StartPatrol() {
        _stopped = false;
        _endingTurn = false;
        _currentDirection = Vector2I.Down;
        Visible = true;
        _animatedSprite2D.Play("bot_animation");
        ScheduleNextStep();
    }

    public void StopPatrol() {
        _stopped = true;
        GoToStarterPoint();
    }

    private void ScheduleNextStep() {
        _patrolTimer = GetTree().CreateTimer(1.0f);
        _patrolTimer.Timeout += OnPatrolTimerTimeout;
    }

    private void OnPatrolTimerTimeout() {
        if (!IsInstanceValid(this)) {
            return;
        }

        if (_stopped) {
            return;
        }

        // ─── Phase A: PreBlockExecute（统计行为、修饰器在此触发） ───
        _battleTime.SayPreBlockExecute();

        // Bot 移动到下一格（过程中若遇到 Block，执行 Phase B）
        MoveToNextCell();

        // 如果 EndTurn 在 MoveToNextCell 中被调用，停止此 tick 的后续流程
        if (_endingTurn) {
            return;
        }

        // ─── Phase C: PostBlockExecute（反击、触发类效果在此触发） ───
        _battleTime.SayPostBlockExecute();

        ScheduleNextStep();
    }

    public override void _ExitTree() {
        if (_patrolTimer != null && IsInstanceValid(_patrolTimer)) {
            _patrolTimer.Timeout -= OnPatrolTimerTimeout;
        }
    }

    /// <summary>
    ///     Bot 移动到下一个格子。通过网格状态检测方块（无需物理碰撞）。
    ///     默认方向为 Down（蛇形巡逻），遇到方块改变方向后沿新方向移动直到边界。
    /// </summary>
    private void MoveToNextCell() {
        if (!TryCalculateNextCell(out var newPos)) {
            EndTurn();
            return;
        }

        var targetHasBlock = Glob.GetGridState(newPos.X, newPos.Y) == Glob.GridState.Occupied;

        ReleaseCellSafely(_currentGridPos);

        _currentGridPos = newPos;
        GlobalPosition = Glob.GetGridPos(_currentGridPos);
        Glob.SetGridState(_currentGridPos.X, _currentGridPos.Y, Glob.GridState.Occupied);

        if (targetHasBlock) {
            EnqueueBlockActionsAt(newPos);
        }
    }

    private bool TryCalculateNextCell(out Vector2I newPos) {
        newPos = _currentGridPos + _currentDirection;

        if (_currentDirection == Vector2I.Down) {
            if (newPos.Y > 4) {
                newPos = new Vector2I(_currentGridPos.X + 1, 0);
            }

            if (newPos.X > 6) {
                return false;
            }
        }
        else if (IsOutOfBounds(newPos)) {
            return false;
        }

        return true;
    }

    private static bool IsOutOfBounds(Vector2I pos) {
        return pos.X < 0 || pos.X > 6 || pos.Y < 0 || pos.Y > 4;
    }

    /// <summary>
    ///     在指定网格坐标查找方块，将其所有 BlockPart 的行为转变为 AbstractAction
    ///     加入 ActionQueue。方向修改同步生效，其他效果异步排队。
    /// </summary>
    private void EnqueueBlockActionsAt(Vector2I gridPos) {
        foreach (var block in _blockPilesHere.PlacedPile.Pile) {
            foreach (var part in block.GetParts()) {
                if (!IsPartAtGrid(part, gridPos)) {
                    continue;
                }

                GD.Print($"Bot 在 ({gridPos.X}, {gridPos.Y}) 检测到 BlockPart: {part.Name}");
                ProcessBlockPart(block, part);
                return;
            }
        }
    }

    private static bool IsPartAtGrid(BlockPart part, Vector2I gridPos) {
        var partGridPoint = Glob.FindNearestGridPoint(part.GlobalPosition);
        var coords = Glob.GetGridCoords(partGridPoint);
        return coords == gridPos;
    }

    private void ProcessBlockPart(Block block, BlockPart part) {
        _battleTime.SayBlockExecute();

        var moveDir = part.PartDefinition?.MovingDirection ?? Vector2I.Down;
        _currentDirection = moveDir;
        if (moveDir != Vector2I.Down) {
            GD.Print($"  Bot 方向改为 ({moveDir.X}, {moveDir.Y})");
        }

        if (part.PartDefinition?.Behaviors == null) {
            return;
        }

        var shouldExhaust = false;
        foreach (var behavior in part.PartDefinition.Behaviors) {
            var action = behavior?.CreateAction(block, part);
            if (action != null) {
                ActionManager.Instance?.AddToBottom(action);
                GD.Print($"  队列加入 Action: {action.GetType().Name} (amount={action.Amount})");
                if (action.ExhaustSourceBlock) {
                    shouldExhaust = true;
                }
            }
        }

        // 如果有任何一个 Action 声明了 ExhaustSourceBlock，立即将 Block 移出战斗
        if (shouldExhaust && block.Faction == Block.BlockFaction.Player) {
            GD.Print($"  Block {block.Definition?.BlockName} 被耗尽，移出战斗");
            ExhaustBlock(block);
        }
    }

    /// <summary>
    ///     将 Block 从本场战斗中移除：释放网格、移出 PlacedPile、销毁节点。
    ///     Block 不会进入弃牌堆，也不会参与洗牌。
    /// </summary>
    private void ExhaustBlock(Block block) {
        foreach (var p in block.GetParts()) {
            var gridPoint = Glob.FindNearestGridPoint(p.GlobalPosition);
            var coords = Glob.GetGridCoords(gridPoint);
            if (coords.X >= 0 && coords.Y >= 0) {
                Glob.RestoreGridState(coords.X, coords.Y);
            }
        }

        _blockPilesHere.PlacedPile.RemoveBlock(block);
        if (block.GetParent() != null && IsInstanceValid(block.GetParent())) {
            block.GetParent().RemoveChild(block);
        }
        block.QueueFree();
    }

    private void EndTurn() {
        GD.Print("Bot 回合结束");
        _stopped = true;
        _endingTurn = true;
        _battleTime.SayTurnEnded();
        GoToStarterPoint();
    }

    private void ReleaseCellSafely(Vector2I pos) {
        if (IsOutOfBounds(pos)) {
            return;
        }

        if (!HasEnemyBlockAt(pos) &&
            Glob.GetGridState(pos.X, pos.Y) != Glob.GridState.Unable) {
            Glob.RestoreGridState(pos.X, pos.Y);
        }
    }

    private void GoToStarterPoint() {
        GlobalPosition = new Vector2(
            Glob.GetGridPos(new Vector2I(0, 0)).X,
            Glob.GetGridPos(new Vector2I(0, 0)).Y - 96
        );

        ReleaseCellSafely(_currentGridPos);

        _currentGridPos = new Vector2I(0, -1);
        _animatedSprite2D.Stop();
        Visible = false;
    }

    private bool HasEnemyBlockAt(Vector2I gridPos) {
        return _blockPilesHere.PlacedPile.Pile.Any(block => {
            if (block.Faction != Block.BlockFaction.Enemy) {
                return false;
            }

            return block.GetParts().Any(part => {
                var coords = Glob.GetGridCoords(Glob.FindNearestGridPoint(part.GlobalPosition));
                return coords == gridPos;
            });
        });
    }
}