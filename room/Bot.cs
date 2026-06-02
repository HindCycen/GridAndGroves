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
        var newPos = _currentGridPos + _currentDirection;

        // 蛇形折行：默认 Down 方向到达底部时换到下一列顶部
        if (_currentDirection == Vector2I.Down) {
            if (newPos.Y > 4) {
                newPos = new Vector2I(_currentGridPos.X + 1, 0);
            }

            if (newPos.X > 6) {
                EndTurn();
                return;
            }
        }
        // 非默认方向：严格边界检测，出界则结束回合
        else if (newPos.X < 0 || newPos.X > 6 || newPos.Y < 0 || newPos.Y > 4) {
            EndTurn();
            return;
        }

        // 在占据新格子前，检测目标格是否已被方块占据
        var targetHasBlock = Glob.GetGridState(newPos.X, newPos.Y) == Glob.GridState.Occupied;

        // 释放当前格子（但保留敌方方块和不可用格子的占用）
        if (!HasEnemyBlockAt(_currentGridPos) &&
            Glob.GetGridState(_currentGridPos.X, _currentGridPos.Y) != Glob.GridState.Unable) {
            Glob.RestoreGridState(_currentGridPos.X, _currentGridPos.Y);
        }

        _currentGridPos = newPos;
        GlobalPosition = Glob.GetGridPos(_currentGridPos);

        // 占据新格子
        Glob.SetGridState(_currentGridPos.X, _currentGridPos.Y, Glob.GridState.Occupied);

        // 如果目标格有方块，将方块行为转变为 Action 加入队列（Phase B）
        if (targetHasBlock) {
            EnqueueBlockActionsAt(newPos);
        }
    }

    /// <summary>
    ///     在指定网格坐标查找方块，将其所有 BlockPart 的行为转变为 AbstractAction
    ///     加入 ActionQueue。方向修改同步生效，其他效果异步排队。
    /// </summary>
    private void EnqueueBlockActionsAt(Vector2I gridPos) {
        foreach (var block in _blockPilesHere.PlacedPile.Pile) {
            foreach (var part in block.GetParts()) {
                var partGridPoint = Glob.FindNearestGridPoint(part.GlobalPosition);
                var coords = Glob.GetGridCoords(partGridPoint);
                if (coords != gridPos) {
                    continue;
                }

                GD.Print($"Bot 在 ({gridPos.X}, {gridPos.Y}) 检测到 BlockPart: {part.Name}");

                // Phase B 信号：告知 Stat 的 OnBlockExecute 钩子
                _battleTime.SayBlockExecute();

                // 获取 MovingDirection —— 这是同步的，立即影响巡逻方向
                var moveDir = part.PartDefinition?.MovingDirection ?? Vector2I.Down;
                // 总是设置巡逻方向：Down 表示恢复蛇形，否则按块指定的方向走
                _currentDirection = moveDir;
                if (moveDir != Vector2I.Down) {
                    GD.Print($"  Bot 方向改为 ({moveDir.X}, {moveDir.Y})");
                }

                // 每个 Behavior 创建 Action 入队
                if (part.PartDefinition?.Behaviors != null) {
                    foreach (var behavior in part.PartDefinition.Behaviors) {
                        var action = behavior?.CreateAction(block, part);
                        if (action != null) {
                            ActionQueue.Instance?.AddToBottom(action);
                            GD.Print($"  队列加入 Action: {action.GetType().Name} (amount={action.Amount})");
                        }
                    }
                }

                // 同一个 Block 可能有多个 part 在同一坐标？一般只有一个，找到了就返回
                return;
            }
        }
    }

    private void EndTurn() {
        GD.Print("Bot 回合结束");
        _stopped = true;
        _endingTurn = true;
        _battleTime.SayTurnEnded();
        GoToStarterPoint();
    }

    private void GoToStarterPoint() {
        GlobalPosition = new Vector2(
            Glob.GetGridPos(new Vector2I(0, 0)).X,
            Glob.GetGridPos(new Vector2I(0, 0)).Y - 96
        );

        // 释放之前占据的网格（但保留敌方方块和不可用格子的占用）
        if (_currentGridPos.X >= 0 && _currentGridPos.X <= 6 &&
            _currentGridPos.Y >= 0 && _currentGridPos.Y <= 4) {
            if (!HasEnemyBlockAt(_currentGridPos) &&
                Glob.GetGridState(_currentGridPos.X, _currentGridPos.Y) != Glob.GridState.Unable) {
                Glob.RestoreGridState(_currentGridPos.X, _currentGridPos.Y);
            }
        }

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