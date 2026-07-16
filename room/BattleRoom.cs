#region

using System.Linq;
using Godot;

#endregion

public partial class BattleRoom : Room {
    private BattleTime _battleTime;
    private BlockPilesHere _blockPilesHere;
    private Bot _bot;
    private Button _endTurnButton;
    private EnemyManager _enemyManager;
    private bool _isGameOver;
    private Player _player;
    private HealthComponent _playerHealth;
    private int _roundNumber;
    [Export] public EnemyChartDef EnemyChart;

    public override void _Ready() {
        base._Ready();

        // 计入房间数（仅在战斗/事件房间增加）
        _saveLoad = GetTree().Root.GetNode<SaveLoad>("SaveLoad");
        if (_saveLoad?.Data != null) {
            _saveLoad.Data.RoomCount++;
        }

        _blockPilesHere = GetNode<BlockPilesHere>("BlockPilesHere");
        _bot = GetNode<Bot>("Bot");
        _battleTime = GetTree().Root.GetNode<BattleTime>("BattleTime");
        _endTurnButton = GetNode<Button>("%Button");
        _enemyManager = GetNode<EnemyManager>("%EnemyManager");

        // 初始化 ActionManager
        var actionManager = GetNodeOrNull<ActionManager>("%ActionManager");
        if (actionManager == null) {
            actionManager = new ActionManager { Name = "ActionManager" };
            AddChild(actionManager);
            actionManager.Owner = this;
        }

        _player = GetNode<Player>("Player");
        _playerHealth = _player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
        _isGameOver = false;

        _playerHealth.Died += OnPlayerDied;

        // 初始化 EnemyManager
        _enemyManager.Initialize(_player, _blockPilesHere);
        _enemyManager.EnemyDied += OnEnemyDiedWrapper;
        _enemyManager.AllEnemiesDefeated += OnAllEnemiesDefeated;

        if (EnemyChart?.EnemyDefs != null) {
            _enemyManager.SpawnFromChart(EnemyChart);
        }

        var enemyCount = _enemyManager.CountAlive();
        GameLog.Debug($"检测到 {enemyCount} 个敌人");
        if (enemyCount == 0) {
            GameLog.Err("没有敌人！请配置 EnemyChart。");
            return;
        }

        _endTurnButton.Text = "End Turn";
        _endTurnButton.Pressed += OnEndTurnPressed;

        _battleTime.TurnEnded += OnBotTurnEnded;
        _battleTime.BattleEnded += OnBattleEndedCleanup;

        InitializePlayerDeck();

        _blockPilesHere.InitializeDrawPile();

        RenderUnableGridCells();

        SetupPileViewerButtons();

        _roundNumber = 0;
        StartPlayerTurn();
    }

    /// <summary>
    ///     敌人死亡时的包装方法，防止重复触发。
    /// </summary>
    private void OnEnemyDiedWrapper() {
        if (_isGameOver) return;
        // AllEnemiesDefeated 信号会在全部死亡时触发
    }

    /// <summary>
    ///     所有敌人被击败时触发胜利流程。
    /// </summary>
    private void OnAllEnemiesDefeated() {
        if (_isGameOver) return;
        _bot.StopPatrol();
        OnVictory();
    }

    public override void _ExitTree() {
        if (ActionManager.Instance != null) {
            ActionManager.Instance.Clear();
        }

        if (_battleTime != null) {
            _battleTime.TurnEnded -= OnBotTurnEnded;
            _battleTime.BattleEnded -= OnBattleEndedCleanup;
        }

        if (_playerHealth != null) {
            _playerHealth.Died -= OnPlayerDied;
        }

        if (_endTurnButton != null) {
            _endTurnButton.Pressed -= OnEndTurnPressed;
        }

        if (_enemyManager != null) {
            _enemyManager.EnemyDied -= OnEnemyDiedWrapper;
            _enemyManager.AllEnemiesDefeated -= OnAllEnemiesDefeated;
        }

        base._ExitTree();
    }

    private void InitializePlayerDeck() {
        var playerPile = GetNode<PileComponent>("Player/PlayerPile");

        if (playerPile.Count > 0) {
            GameLog.Info("存档已存在，保留存档中的卡组");
            GameLog.Debug($"玩家牌组已初始化，共 {playerPile.Count} 张牌");
            return;
        }

        // 优先从 StageDef.StartingDeck 读取初始牌组
        var stageDef = GetStageDef();
        var startingDeck = stageDef?.StartingDeck;
        if (startingDeck is { Length: > 0 }) {
            foreach (var blockName in startingDeck) {
                var block = Glob.CreateBlock(blockName);
                if (block != null) {
                    playerPile.AddBlock(block);
                }
                else {
                    GameLog.Err($"InitializePlayerDeck: 找不到方块 [{blockName}]");
                }
            }
        }
        else {
            // 兜底：硬编码默认牌组
            for (var i = 0; i < 3; i++) playerPile.AddBlock(Glob.CreateBlock("DamageBlock"));
            for (var i = 0; i < 2; i++) playerPile.AddBlock(Glob.CreateBlock("ExampleMoveRight"));
            for (var i = 0; i < 2; i++) playerPile.AddBlock(Glob.CreateBlock("ExampleBlock"));
            playerPile.AddBlock(Glob.CreateBlock("Growing"));
            playerPile.AddBlock(Glob.CreateBlock("Shield"));
        }

        GameLog.Debug($"玩家牌组已初始化，共 {playerPile.Count} 张牌");
    }

    /// <summary>
    ///     向上查找当前 StageDef。从 StageRoom 传入的 StageDef 存档中恢复。
    /// </summary>
    private StageDef GetStageDef() {
        // 尝试从 SaveLoad 中的 StageDefPath 加载
        var path = _saveLoad?.Data?.StageDefPath;
        if (!string.IsNullOrEmpty(path)) {
            var loaded = GD.Load<StageDef>(path);
            if (loaded != null) return loaded;
        }
        // 兜底：加载示例 StageDef
        return GD.Load<StageDef>("res://resources/EgStageDef.tres");
    }

    private void StartPlayerTurn() {
        _roundNumber++;
        GameLog.Info($"\n=== 第 {_roundNumber} 回合 ===");

        Block.InputLocked = false;

        _enemyManager.ClearOldBlocks();
        _enemyManager.ExecuteTurn();

        _blockPilesHere.ClearPlayerRound();

        _battleTime.SayTurnStarted();

        _blockPilesHere.DrawCards(3);

        _endTurnButton.Disabled = false;
        _endTurnButton.Text = "End Turn";
    }

    private void OnEndTurnPressed() {
        _endTurnButton.Disabled = true;
        _endTurnButton.Text = "Bot's Turn...";
        GameLog.Debug("\n=== Bot 执行阶段 ===");

        Block.InputLocked = true;
        _bot.StartPatrol();
    }

    private void OnBotTurnEnded() {
        GameLog.Debug("Bot 执行结束");

        // 将敌人攻击通过 EnemyManager 入队（走 DamageAction，触发 Stat 钩子）
        _enemyManager.QueueAttacks(this, OnAllEnemyAttacksResolved);
    }

    private void OnVictory() {
        GameLog.Info("\n=== 胜利！所有敌人已被击败！===");
        _endTurnButton.Text = "Victory!";
        _endTurnButton.Disabled = true;
        _battleTime.SayBattleEnded();

        // 判断是否 Boss 战（roomCount == 20），是则进入下一层
        var isBoss = _saveLoad?.Data?.RoomCount >= 20;
        if (isBoss) {
            GameLog.Info("Boss 击杀！进入下一层");
        }

        _saveLoad.Save();

        var timer = GetTree().CreateTimer(1.0);
        timer.Timeout += () => {
            if (isBoss) {
                _saveLoad.AdvanceToNextFloor();
            }

            var stageScene = GD.Load<PackedScene>("res://room/StageRoom.tscn");
            var stage = stageScene.Instantiate<StageRoom>();
            GetTree().Root.AddChild(stage);
            QueueFree();
        };
    }

    private void OnPlayerDied() {
        _isGameOver = true;
        OnDefeat();
    }

    private void OnDefeat() {
        GameLog.Info("\n=== 败北！玩家已被击败！===");
        _endTurnButton.Text = "Defeat...";
        _endTurnButton.Disabled = true;
        _bot.StopPatrol();
        _battleTime.SayBattleEnded();

        // 短暂延迟后显示 Game Over 画面
        var timer = GetTree().CreateTimer(1.5);
        timer.Timeout += () => {
            var gameOverScene = GD.Load<PackedScene>("res://GameOver.tscn");
            var gameOver = gameOverScene.Instantiate<GameOver>();
            GetTree().Root.AddChild(gameOver);
            QueueFree();
        };
    }

    /// <summary>
    ///     战斗结束清理：
    ///     移除玩家身上标记了 RemoveOnBattleEnd 的临时状态（药水效果）。
    ///     永久状态（遗物效果）保留，由 SaveLoad 持久化。
    /// </summary>
    private void OnBattleEndedCleanup() {
        if (!IsInstanceValid(_player)) {
            return;
        }

        var rend = _player.GetNodeOrNull<RenderingComponent>("RenderingComponent");
        var statsComponent = rend?.StatsComponent;
        if (statsComponent == null) {
            return;
        }

        var tempStats = statsComponent.GetAllStatuses()
            .Where(s => s.Definition?.RemoveOnBattleEnd == true)
            .ToList();

        foreach (var stat in tempStats) {
            GameLog.Info($"战斗结束，移除临时状态 [{stat.Definition?.StatName}]");
            statsComponent.RemoveStatus(stat.Definition?.StatName);
        }
    }

    /// <summary>
    ///     所有敌人攻击动作执行完毕后的回调。
    ///     检查玩家是否死亡、敌人是否全灭，然后开始下一回合或结束战斗。
    /// </summary>
    private void OnAllEnemyAttacksResolved() {
        if (_isGameOver) {
            return;
        }

        if (_enemyManager.AreAllDead()) {
            // OnAllEnemiesDefeated 信号会触发 OnVictory
            return;
        }

        GameLog.Debug($"剩余敌人: {_enemyManager.CountAlive()}");

        StartPlayerTurn();
    }

    private void SetupPileViewerButtons() {
        var drawBtn = new Button {
            Text = "抽牌堆"
        };
        drawBtn.SetPosition(new Vector2I(20, 1030));
        drawBtn.SetSize(new Vector2I(120, 40));
        drawBtn.Pressed += () => ShowPileViewer("抽牌堆", _blockPilesHere.DrawPile);
        AddChild(drawBtn);

        var discardBtn = new Button {
            Text = "弃牌堆"
        };
        discardBtn.SetPosition(new Vector2I(1780, 1030));
        discardBtn.SetSize(new Vector2I(120, 40));
        discardBtn.Pressed += () => ShowPileViewer("弃牌堆", _blockPilesHere.DiscardedPile);
        AddChild(discardBtn);
    }

    private void ShowPileViewer(string title, PileComponent pile) {
        var viewer = GD.Load<PackedScene>("res://components/PileViewer.tscn").Instantiate<PileViewer>();
        viewer.Show(title, pile);
        AddChild(viewer);
    }

    private void RenderUnableGridCells() {
        var texture = GD.Load<Texture2D>("res://room/battle_background/UnableGrid.png");
        var texSize = texture.GetSize();
        var scale = new Vector2(96 / texSize.X, 96 / texSize.Y);
        var bgNode = GetNode<Node2D>("BackgroundAnimator");

        for (var col = 0; col < 7; col++) {
            for (var row = 0; row < 5; row++) {
                if (Glob.GetGridState(col, row) != Glob.GridState.Unable) {
                    continue;
                }

                var sprite = new Sprite2D {
                    Texture = texture,
                    Scale = scale,
                    ZIndex = 0,
                    GlobalPosition = Glob.GetGridPos(new Vector2I(col, row))
                };
                bgNode.AddChild(sprite);
            }
        }
    }
}