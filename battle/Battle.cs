#region

using System.Linq;
using Godot;

#endregion

public partial class Battle : Node2D {
    private BlockPilesHere _blockPilesHere;
    private Bot _bot;
    private Button _endTurnButton;
    private BattleTime _battleTime;
    private int _roundNumber;
    private Enemy[] _enemies;

    public override void _Ready() {
        _blockPilesHere = GetNode<BlockPilesHere>("BlockPilesHere");
        _bot = GetNode<Bot>("Bot");
        _battleTime = GetTree().Root.GetNode<BattleTime>("BattleTime");
        _endTurnButton = GetNode<Button>("%Button");
        _enemies = GetTree().GetNodesInGroup("Enemies").OfType<Enemy>().ToArray();

        GD.Print($"检测到 {_enemies.Length} 个敌人");

        // 配置"结束回合"按钮
        _endTurnButton.Text = "End Turn";
        _endTurnButton.Pressed += OnEndTurnPressed;

        // Bot 回合结束时触发
        _battleTime.TurnEnded += OnBotTurnEnded;

        // 初始化玩家牌组（放入初始卡片）
        InitializePlayerDeck();

        // 初始化抽牌堆（将玩家牌组的副本移入）
        _blockPilesHere.InitializeDrawPile();

        // 开始游戏
        _roundNumber = 0;
        StartPlayerTurn();
    }

    /// <summary>
    /// 初始化玩家起始牌组
    /// </summary>
    private void InitializePlayerDeck() {
        var playerPile = GetNode<PileComponent>("Player/PlayerPile");

        // 示例方块：用于检验抽牌、放置等功能
        for (var i = 0; i < 3; i++) {
            playerPile.AddBlock(Glob.CreateBlock("DamageBlock"));
        }
        for (var i = 0; i < 2; i++) {
            playerPile.AddBlock(Glob.CreateBlock("ExampleMoveRight"));
        }
        for (var i = 0; i < 2; i++) {
            playerPile.AddBlock(Glob.CreateBlock("ExampleBlock"));
        }

        GD.Print($"玩家牌组已初始化，共 {playerPile.Count} 张牌");
    }

    /// <summary>
    /// 玩家回合：抽牌，等待放置方块
    /// </summary>
    private void StartPlayerTurn() {
        _roundNumber++;
        GD.Print($"\n=== 第 {_roundNumber} 回合 - 玩家回合 ===");

        // 清空上一回合的牌面
        _blockPilesHere.ClearRound();

        // 发射回合开始信号（触发 Stat 效果等）
        _battleTime.SayTurnStarted();

        // 抽牌
        _blockPilesHere.DrawCards(3);

        // 启用结束按钮
        _endTurnButton.Disabled = false;
        _endTurnButton.Text = "End Turn";
    }

    /// <summary>
    /// 玩家点击"结束回合" → 开始 Bot 巡逻执行阶段
    /// </summary>
    private void OnEndTurnPressed() {
        _endTurnButton.Disabled = true;
        _endTurnButton.Text = "Bot's Turn...";
        GD.Print("\n=== Bot 执行阶段 ===");

        _bot.StartPatrol();
    }

    /// <summary>
    /// Bot 执行结束 → 检查所有敌人是否死亡 → 开始下一玩家回合
    /// </summary>
    private void OnBotTurnEnded() {
        GD.Print("Bot 执行结束");

        // 检查所有敌人是否被击败
        if (AreAllEnemiesDead()) {
            OnVictory();
            return;
        }

        GD.Print($"剩余敌人: {CountAliveEnemies()}");

        // 开始下一玩家回合
        StartPlayerTurn();
    }

    private bool AreAllEnemiesDead() {
        // 重新获取敌人列表（可能已销毁）
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
    }
}
