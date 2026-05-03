#region

using System.Linq;
using Godot;

#endregion

public partial class SaveLoad : Node {
    private const string DefaultSavePath = "user://savegame.tres";

    public DataResource Data { get; private set; }

    public override void _Ready() {
        Data = new DataResource();
    }

    public void Save(string path = DefaultSavePath) {
        SyncFromGameState();
        var result = ResourceSaver.Save(Data, path);
        if (result != Error.Ok) {
            GD.PrintErr($"SaveLoad: 保存失败 ({result})");
        }
    }

    public void Load(string path = DefaultSavePath) {
        if (!ResourceLoader.Exists(path)) {
            GD.Print($"SaveLoad: 存档文件不存在 ({path})，使用默认初始数据");
            return;
        }

        var loaded = ResourceLoader.Load<DataResource>(path);
        if (loaded == null) {
            GD.PrintErr("SaveLoad: 加载存档失败");
            return;
        }

        Data = loaded;
        SyncToGameState();
    }

    private void SyncFromGameState() {
        Data.Seed = Glob.GetCurrentSeed();
        Data.MapRandUsage = Glob.GetMapRandUsage();
        Data.MonsterRandUsage = Glob.GetMonsterRandUsage();
        Data.RewardRandUsage = Glob.GetRewardRandUsage();
        Data.ChestRandUsage = Glob.GetChestRandUsage();
        Data.MiscRandUsage = Glob.GetMiscRandUsage();
        Data.PileRandUsage = Glob.GetPileRandUsage();

        var player = GetTree().GetFirstNodeInGroup("Players") as Player;
        if (player == null) {
            return;
        }

        var health = player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
        if (health != null) {
            Data.PlayerCurrentHealth = health.CurrentHealth;
            Data.PlayerMaxHealth = health.MaxHealth;
        }

        var pile = player.GetNode<PileComponent>("%PlayerPile");
        if (pile != null) {
            Data.PlayerDeckBlockNames = pile.Pile
                .Select(b => b.Definition?.BlockName)
                .Where(name => name != null)
                .ToArray();
        }

        var rend = player.GetNode<RenderingComponent>("RenderingComponent");
        if (rend?.StatsComponent != null) {
            var stats = rend.StatsComponent.GetAllStatuses();
            Data.PlayerStatNames = stats.Select(s => s.Definition?.StatName).Where(n => n != null).ToArray();
            Data.PlayerStatValues = stats.Select(s => s.CurrentValue).ToArray();
        }
    }

    private void SyncToGameState() {
        Glob.RestoreRngFromUsage(
            Data.Seed,
            Data.MapRandUsage,
            Data.MonsterRandUsage,
            Data.RewardRandUsage,
            Data.ChestRandUsage,
            Data.MiscRandUsage,
            Data.PileRandUsage
        );

        var player = GetTree().GetFirstNodeInGroup("Players") as Player;
        if (player == null) {
            return;
        }

        player.StageCount = Data.StageCount;
        player.RoomCount = Data.RoomCount;

        var health = player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
        if (health != null && Data.PlayerMaxHealth > 0) {
            health.SetMaxHealth(Data.PlayerMaxHealth);
            health.SetCurrentHealth(Data.PlayerCurrentHealth);
        }

        var pile = player.GetNode<PileComponent>("%PlayerPile");
        if (pile != null && Data.PlayerDeckBlockNames != null) {
            var existing = pile.Pile.ToList();
            foreach (var block in existing) {
                pile.RemoveBlock(block);
                block.QueueFree();
            }

            foreach (var blockName in Data.PlayerDeckBlockNames) {
                var block = Glob.CreateBlock(blockName);
                if (block != null) {
                    pile.AddBlock(block);
                }
            }
        }

        var rend = player.GetNode<RenderingComponent>("RenderingComponent");
        if (rend?.StatsComponent != null && Data.PlayerStatNames != null && Data.PlayerStatValues != null) {
            var statsComp = rend.StatsComponent;
            var count = Mathf.Min(Data.PlayerStatNames.Length, Data.PlayerStatValues.Length);
            for (var i = 0; i < count; i++) {
                var stat = statsComp.GetStatus(Data.PlayerStatNames[i]);
                if (stat != null) {
                    stat.SetValue(Data.PlayerStatValues[i]);
                }
                else {
                    var statDef = GD.Load<StatDef>($"res://resources/stat_defs/{Data.PlayerStatNames[i]}.tres");
                    if (statDef != null) {
                        stat = new Stat { Definition = statDef };
                        statsComp.AddStatus(stat);
                        stat.SetValue(Data.PlayerStatValues[i]);
                    }
                }
            }
        }
    }
}
