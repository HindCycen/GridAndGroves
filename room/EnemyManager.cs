#region

using System.Linq;
using Godot;

#endregion

/// <summary>
///     敌人管理器。负责敌人的生成、AI 执行、攻击入队和状态查询。
///     作为 BattleRoom 的子节点，管理所有敌人相关的逻辑。
/// </summary>
public partial class EnemyManager : Node {
    [Signal]
    public delegate void EnemyDiedEventHandler();

    [Signal]
    public delegate void AllEnemiesDefeatedEventHandler();

    private BlockPilesHere _blockPilesHere;
    private Enemy[] _enemies = [];
    private Player _player;

    /// <summary>
    ///     初始化敌人管理器。
    /// </summary>
    public void Initialize(Player player, BlockPilesHere blockPilesHere) {
        _player = player;
        _blockPilesHere = blockPilesHere;
    }

    /// <summary>
    ///     从 EnemyChartDef 生成敌人，清除已有的敌人。
    /// </summary>
    public void SpawnFromChart(EnemyChartDef chart) {
        // 清除现有敌人
        var existing = GetTree().GetNodesInGroup("Enemies").OfType<Enemy>().ToList();
        foreach (var enemy in existing) {
            if (IsInstanceValid(enemy)) {
                enemy.GetParent()?.RemoveChild(enemy);
                enemy.QueueFree();
            }
        }

        if (chart?.EnemyDefs == null) {
            _enemies = [];
            return;
        }

        var index = 0;
        foreach (var enemyDef in chart.EnemyDefs) {
            if (enemyDef == null) continue;

            var enemyScene = GD.Load<PackedScene>("res://actors/enemy/Enemy.tscn");
            var enemy = enemyScene.Instantiate<Enemy>();
            enemy.Definition = enemyDef;
            enemy.Position = new Vector2(1300 + index * 200, 150 + index % 2 * 200);
            AddChild(enemy);
            GameLog.Debug($"SpawnFromChart: 生成敌人 {enemyDef.EnemyName} 在 ({enemy.Position.X}, {enemy.Position.Y})");
            index++;
        }

        RefreshEnemyList();

        // 连接每个敌人的死亡信号
        foreach (var enemy in _enemies) {
            enemy.SetupAI(_blockPilesHere);
            var hc = enemy.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
            if (hc != null) {
                hc.Died += OnEnemyDied;
            }
        }
    }

    /// <summary>
    ///     清理所有存活敌人的旧方块（每回合开始时调用）。
    /// </summary>
    public void ClearOldBlocks() {
        RefreshEnemyList();
        GameLog.Debug($"清理 {_enemies.Length} 个敌人的旧方块");
        foreach (var enemy in _enemies) {
            if (!IsInstanceValid(enemy)) continue;
            var hc = enemy.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
            if (hc == null || hc.IsDead) continue;
            enemy.ClearBlocks();
        }
    }

    /// <summary>
    ///     让所有存活敌人执行 AI 意图（每回合开始时调用）。
    /// </summary>
    public void ExecuteTurn() {
        RefreshEnemyList();
        GameLog.Debug($"执行 {_enemies.Length} 个敌人的 AI 意图");
        foreach (var enemy in _enemies) {
            if (!IsInstanceValid(enemy)) continue;
            var hc = enemy.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
            if (hc == null || hc.IsDead) continue;
            enemy.ExecuteTurn();
        }
    }

    /// <summary>
    ///     将所有存活敌人的攻击转为 DamageAction 入队。
    ///     全部入队后追加一个 CallbackAction，完成后调用 onAllResolved。
    /// </summary>
    public void QueueAttacks(Node source, System.Action onAllResolved) {
        RefreshEnemyList();
        foreach (var enemy in _enemies) {
            if (!IsInstanceValid(enemy)) continue;
            var hc = enemy.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
            if (hc == null || hc.IsDead) continue;

            var damage = enemy.AttackDamage;
            GameLog.Debug($"敌人 {enemy.Name} 对玩家造成 {damage} 点伤害");
            ActionManager.Instance?.AddToBottom(new DamageAction(enemy, _player, damage, 0.2f));
        }

        ActionManager.Instance?.AddToBottom(new CallbackAction(onAllResolved));
    }

    /// <summary>
    ///     检查是否所有敌人都已死亡。
    /// </summary>
    public bool AreAllDead() {
        RefreshEnemyList();
        return _enemies.Length == 0 || _enemies.All(e => {
            if (!IsInstanceValid(e)) return true;
            var hc = e.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
            return hc == null || hc.IsDead;
        });
    }

    /// <summary>
    ///     统计存活的敌人数量。
    /// </summary>
    public int CountAlive() {
        RefreshEnemyList();
        return _enemies.Count(e => {
            if (!IsInstanceValid(e)) return false;
            var hc = e.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
            return hc != null && !hc.IsDead;
        });
    }

    /// <summary>
    ///     敌人死亡时的内部处理。发出信号让 BattleRoom 响应。
    /// </summary>
    private void OnEnemyDied() {
        EmitSignalEnemyDied();

        if (AreAllDead()) {
            EmitSignalAllEnemiesDefeated();
        }
    }

    /// <summary>
    ///     刷新敌人列表，从场景组中重新获取。
    /// </summary>
    private void RefreshEnemyList() {
        _enemies = GetTree().GetNodesInGroup("Enemies").OfType<Enemy>().ToArray();
    }
}
