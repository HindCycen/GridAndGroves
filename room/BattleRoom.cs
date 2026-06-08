#region

using System.Linq;
using Godot;

#endregion

public partial class BattleRoom : Room {
    private BattleTime _battleTime;
    private BlockPilesHere _blockPilesHere;
    private Bot _bot;
    private Button _endTurnButton;
    private Enemy[] _enemies;
    private bool _isGameOver;
    private Player _player;
    private HealthComponent _playerHealth;
    private int _roundNumber;
    [Export] public EnemyChartDef EnemyChart;

    public override void _Ready() {
        base._Ready();
        _blockPilesHere = GetNode<BlockPilesHere>("BlockPilesHere");
        _bot = GetNode<Bot>("Bot");
        _battleTime = GetTree().Root.GetNode<BattleTime>("BattleTime");
        _saveLoad = GetTree().Root.GetNode<SaveLoad>("SaveLoad");
        _endTurnButton = GetNode<Button>("%Button");

        // 初始化 ActionManager
        var actionManager = GetNodeOrNull<ActionManager>("%ActionManager");
        if (actionManager == null) {
            actionManager = new ActionManager { Name = "ActionManager" };
            AddChild(actionManager);
            actionManager.Owner = this;
        }

        if (EnemyChart?.EnemyDefs != null) {
            SpawnEnemiesFromChart();
        }

        _enemies = GetTree().GetNodesInGroup("Enemies").OfType<Enemy>().ToArray();
        _player = GetNode<Player>("Player");
        _playerHealth = _player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
        _isGameOver = false;

        _playerHealth.Died += OnPlayerDied;

        GD.Print($"检测到 {_enemies.Length} 个敌人");
        if (_enemies.Length == 0) {
            GD.PrintErr("没有敌人！请配置 EnemyChart 或在场景中放置 Enemy 节点。");
            return;
        }

        _endTurnButton.Text = "End Turn";
        _endTurnButton.Pressed += OnEndTurnPressed;

        _battleTime.TurnEnded += OnBotTurnEnded;
        _battleTime.BattleEnded += OnBattleEndedCleanup;

        InitializePlayerDeck();

        _blockPilesHere.InitializeDrawPile();

        foreach (var enemy in _enemies) {
            enemy.SetupAI(_blockPilesHere);
            var hc = enemy.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (hc != null) {
                hc.Died += OnEnemyDied;
            }
        }

        RenderUnableGridCells();

        SetupPileViewerButtons();

        _roundNumber = 0;
        StartPlayerTurn();
    }

    public override void _ExitTree() {
        // 清理 ActionManager 的单例引用
        if (ActionManager.Instance != null) {
            ActionManager.Instance.Clear();
        }

        base._ExitTree();
    }

    private void InitializePlayerDeck() {
        var playerPile = GetNode<PileComponent>("Player/PlayerPile");

        if (playerPile.Count > 0) {
            GD.Print("存档已存在，保留存档中的卡组");
            GD.Print($"玩家牌组已初始化，共 {playerPile.Count} 张牌");
            return;
        }

        for (var i = 0; i < 3; i++) {
            playerPile.AddBlock(Glob.CreateBlock("DamageBlock"));
        }

        for (var i = 0; i < 2; i++) {
            playerPile.AddBlock(Glob.CreateBlock("ExampleMoveRight"));
        }

        for (var i = 0; i < 2; i++) {
            playerPile.AddBlock(Glob.CreateBlock("ExampleBlock"));
        }

        playerPile.AddBlock(Glob.CreateBlock("Growing"));

        GD.Print($"玩家牌组已初始化，共 {playerPile.Count} 张牌");
    }

    private void StartPlayerTurn() {
        _roundNumber++;
        GD.Print($"\n=== 第 {_roundNumber} 回合 ===");

        Block.InputLocked = false;

        MakeEnemiesClearOldBlocks();
        MakeEnemiesExecuteTurn();

        _blockPilesHere.ClearPlayerRound();

        _battleTime.SayTurnStarted();

        _blockPilesHere.DrawCards(3);

        _endTurnButton.Disabled = false;
        _endTurnButton.Text = "End Turn";
    }

    private void OnEndTurnPressed() {
        _endTurnButton.Disabled = true;
        _endTurnButton.Text = "Bot's Turn...";
        GD.Print("\n=== Bot 执行阶段 ===");

        Block.InputLocked = true;
        _bot.StartPatrol();
    }

    private void OnBotTurnEnded() {
        GD.Print("Bot 执行结束");

        // 将敌人攻击改为通过 ActionManager 入队（走 DamageAction，触发 Stat 钩子）
        QueueEnemyAttacks();
    }

    private bool AreAllEnemiesDead() {
        _enemies = GetTree().GetNodesInGroup("Enemies").OfType<Enemy>().ToArray();
        return _enemies.Length == 0 || _enemies.All(e => {
            var hc = e.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            return hc == null || hc.IsDead;
        });
    }

    private int CountAliveEnemies() {
        _enemies = GetTree().GetNodesInGroup("Enemies").OfType<Enemy>().ToArray();
        return _enemies.Count(e => {
            var hc = e.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            return hc != null && !hc.IsDead;
        });
    }

    private void OnVictory() {
        GD.Print("\n=== 胜利！所有敌人已被击败！===");
        _endTurnButton.Text = "Victory!";
        _endTurnButton.Disabled = true;
        _battleTime.SayBattleEnded();
        _saveLoad.Save();

        var timer = GetTree().CreateTimer(1.0);
        timer.Timeout += () => {
            var stageScene = GD.Load<PackedScene>("res://room/StageRoom.tscn");
            var stage = stageScene.Instantiate<StageRoom>();
            GetTree().Root.AddChild(stage);
            QueueFree();
        };
    }

    private void OnEnemyDied() {
        if (_isGameOver) {
            return;
        }


        if (AreAllEnemiesDead()) {
            _bot.StopPatrol();
            OnVictory();
        }
    }

    private void OnPlayerDied() {
        _isGameOver = true;
        OnDefeat();
    }

    private void OnDefeat() {
        GD.Print("\n=== 败北！玩家已被击败！===");
        _endTurnButton.Text = "Defeat...";
        _endTurnButton.Disabled = true;
        _bot.StopPatrol();
        _battleTime.SayBattleEnded();
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
            GD.Print($"战斗结束，移除临时状态 [{stat.Definition?.StatName}]");
            statsComponent.RemoveStatus(stat.Definition?.StatName);
        }
    }

    private void MakeEnemiesClearOldBlocks() {
        _enemies = GetTree().GetNodesInGroup("Enemies").OfType<Enemy>().ToArray();
        GD.Print($"清理 {_enemies.Length} 个敌人的旧方块");
        foreach (var enemy in _enemies) {
            var hc = enemy.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (hc == null || hc.IsDead) {
                continue;
            }

            enemy.ClearBlocks();
        }
    }

    private void MakeEnemiesExecuteTurn() {
        _enemies = GetTree().GetNodesInGroup("Enemies").OfType<Enemy>().ToArray();
        GD.Print($"执行 {_enemies.Length} 个敌人的 AI 意图");
        foreach (var enemy in _enemies) {
            var hc = enemy.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (hc == null || hc.IsDead) {
                continue;
            }

            enemy.ExecuteTurn();
        }
    }

    /// <summary>
    ///     将敌人的攻击转为 DamageAction 入队，走完整的 ActionQueue 管线。
    ///     每个敌人产生一个 DamageAction，全部入队后追加一个 CallbackAction
    ///     等待所有攻击动作完成后再检查胜负。
    /// </summary>
    private void QueueEnemyAttacks() {
        _enemies = GetTree().GetNodesInGroup("Enemies").OfType<Enemy>().ToArray();
        foreach (var enemy in _enemies) {
            var hc = enemy.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (hc == null || hc.IsDead) {
                continue;
            }

            var damage = enemy.AttackDamage;
            GD.Print($"敌人 {enemy.Name} 对玩家造成 {damage} 点伤害");
            ActionManager.Instance?.AddToBottom(new DamageAction(enemy, _player, damage, 0.2f));
        }

        // 所有攻击入队后，追加一个回调等待队列排空后检查胜负
        ActionManager.Instance?.AddToBottom(new CallbackAction(OnAllEnemyAttacksResolved));
    }

    /// <summary>
    ///     所有敌人攻击动作执行完毕后的回调。
    ///     检查玩家是否死亡、敌人是否全灭，然后开始下一回合或结束战斗。
    /// </summary>
    private void OnAllEnemyAttacksResolved() {
        if (_isGameOver) {
            return;
        }

        if (AreAllEnemiesDead()) {
            OnVictory();
            return;
        }

        GD.Print($"剩余敌人: {CountAliveEnemies()}");

        StartPlayerTurn();
    }

    private void SpawnEnemiesFromChart() {
        var existingEnemies = GetTree().GetNodesInGroup("Enemies").OfType<Enemy>().ToList();
        foreach (var enemy in existingEnemies) {
            if (IsInstanceValid(enemy)) {
                RemoveChild(enemy);
                enemy.QueueFree();
            }
        }

        var index = 0;
        foreach (var enemyDef in EnemyChart.EnemyDefs) {
            if (enemyDef == null) {
                continue;
            }


            var enemyScene = GD.Load<PackedScene>("res://actors/enemy/Enemy.tscn");
            var enemy = enemyScene.Instantiate<Enemy>();
            enemy.Definition = enemyDef;
            var x = 1300 + index * 200;
            var y = 150 + index % 2 * 200;
            enemy.Position = new Vector2(x, y);
            AddChild(enemy);
            GD.Print($"SpawnEnemiesFromChart: 生成敌人 {enemyDef.EnemyName} 在 ({x}, {y})");
            index++;
        }
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
        var overlay = new ColorRect {
            Color = new Color(0, 0, 0, 0.6f)
        };
        overlay.SetSize(new Vector2I(1920, 1080));
        overlay.SetPosition(Vector2I.Zero);
        overlay.MouseFilter = Control.MouseFilterEnum.Stop;
        AddChild(overlay);

        var panel = new Panel();
        panel.SetSize(new Vector2I(700, 800));
        panel.SetPosition(new Vector2I(610, 140));
        overlay.AddChild(panel);

        var titleLabel = new Label {
            Text = title
        };
        titleLabel.SetPosition(new Vector2I(20, 10));
        titleLabel.AddThemeFontSizeOverride("font_size", 24);
        panel.AddChild(titleLabel);

        var closeBtn = new Button {
            Text = "关闭"
        };
        closeBtn.SetPosition(new Vector2I(640, 10));
        closeBtn.SetSize(new Vector2I(50, 30));
        closeBtn.Pressed += overlay.QueueFree;
        panel.AddChild(closeBtn);

        var scroll = new ScrollContainer();
        scroll.SetPosition(new Vector2I(20, 50));
        scroll.SetSize(new Vector2I(660, 740));
        panel.AddChild(scroll);

        var vbox = new VBoxContainer();
        scroll.AddChild(vbox);

        if (pile.Count == 0) {
            var empty = new Label {
                Text = "（空）",
                CustomMinimumSize = new Vector2I(0, 30)
            };
            vbox.AddChild(empty);
        }
        else {
            foreach (var block in pile.Pile) {
                var card = new Panel {
                    CustomMinimumSize = new Vector2I(640, 36)
                };

                var nameLabel = new Label {
                    Text = $"  {block.Definition.BlockName}    (Faction: {block.Faction})"
                };
                nameLabel.SetPosition(new Vector2I(10, 8));
                card.AddChild(nameLabel);

                vbox.AddChild(card);
            }
        }
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