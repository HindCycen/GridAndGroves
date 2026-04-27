#region

using System.Linq;
using Godot;

#endregion

public partial class Bot : Node2D {
    private AnimatedSprite2D _animatedSprite2D;
    private BattleTime _battleTime;
    private BlockPilesHere _blockPilesHere;
    private Vector2I _currentDirection = Vector2I.Down;
    private Vector2I _currentGridPos;

    public override void _Ready() {
        _battleTime = GetTree().Root.GetNode<BattleTime>("BattleTime");
        _animatedSprite2D = GetNode<AnimatedSprite2D>("%AnimatedSprite2D");
        _blockPilesHere = GetParent().GetNode<BlockPilesHere>("BlockPilesHere");

        _battleTime.SayBattleStarted();
        Visible = false;
        GoToStarterPoint();
    }

    public void StartPatrol() {
        _currentDirection = Vector2I.Down;
        Visible = true;
        _animatedSprite2D.Play("bot_animation");
        ScheduleNextStep();
    }

    private void ScheduleNextStep() {
        GetTree().CreateTimer(1.0f).Timeout += () => {
            _battleTime.SayTicTac();
            MoveToNextCell();
        };
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

        // 释放当前格子（但保留敌方方块占用的格子）
        if (!HasEnemyBlockAt(_currentGridPos)) {
            Glob.SetGridState(_currentGridPos.X, _currentGridPos.Y, Glob.GridState.Free);
        }

        _currentGridPos = newPos;
        GlobalPosition = Glob.GetGridPos(_currentGridPos);

        // 占据新格子
        Glob.SetGridState(_currentGridPos.X, _currentGridPos.Y, Glob.GridState.Occupied);

        // 如果目标格有方块，执行其行为
        if (targetHasBlock) {
            TryExecuteBlockAt(newPos);
        }

        ScheduleNextStep();
    }

    /// <summary>
    ///     在指定网格坐标查找方块并执行其行为
    /// </summary>
    private void TryExecuteBlockAt(Vector2I gridPos) {
        foreach (var block in _blockPilesHere.PlacedPile.Pile) {
            foreach (var part in block.GetParts()) {
                var partGridPoint = Glob.FindNearestGridPoint(part.GlobalPosition);
                var coords = Glob.GetGridCoords(partGridPoint);
                if (coords == gridPos) {
                    GD.Print($"Bot 在 ({gridPos.X}, {gridPos.Y}) 检测到 BlockPart: {part.Name}");
                    _currentDirection = part.Execute(block);
                    return;
                }
            }
        }
    }

    private void EndTurn() {
        GD.Print("Bot 回合结束");
        _battleTime.SayTurnEnded();
        GoToStarterPoint();
    }

    private void GoToStarterPoint() {
        GlobalPosition = new Vector2(
            Glob.GetGridPos(new Vector2I(0, 0)).X,
            Glob.GetGridPos(new Vector2I(0, 0)).Y - Glob.GridSize
        );

        // 释放之前占据的网格（但保留敌方方块的占用）
        if (_currentGridPos.X >= 0 && _currentGridPos.X <= 6 &&
            _currentGridPos.Y >= 0 && _currentGridPos.Y <= 4) {
            if (!HasEnemyBlockAt(_currentGridPos)) {
                Glob.SetGridState(_currentGridPos.X, _currentGridPos.Y, Glob.GridState.Free);
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