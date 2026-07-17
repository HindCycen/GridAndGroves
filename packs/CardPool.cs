#region

using System.Collections.Generic;
using System.Linq;
using Godot;

#endregion

/// <summary>
///     卡池，由玩家选择的 1 个主卡包（BlockPack）和 4 个小卡包（MiniPack）合并而成。
///     只有卡池中的 Block 才能在本局游戏的任何场合出现（战斗奖励、商店、事件等）。
///     卡池在每局游戏开始时构建，持续到该局游戏结束。
/// </summary>
public class CardPool {
    /// <summary>
    ///     玩家本局选择的主卡包。
    /// </summary>
    public BlockPack MainPack { get; }

    /// <summary>
    ///     本局随机选中的 4 个小卡包。
    /// </summary>
    public MiniPack[] SelectedMiniPacks { get; }

    /// <summary>
    ///     合并后的完整卡池列表（已去重）。
    /// </summary>
    public IReadOnlyList<BlockDef> AllBlockDefs => _allBlockDefs.AsReadOnly();

    /// <summary>
    ///     卡池中的 BlockDef 数量。
    /// </summary>
    public int Count => _allBlockDefs.Count;

    private readonly List<BlockDef> _allBlockDefs = [];

    /// <summary>
    ///     用主卡包和 4 个小卡包构建卡池。
    ///     如果有重复名称的 BlockDef，以先加入的为准（主卡包优先于小卡包）。
    /// </summary>
    /// <param name="mainPack">玩家选择的主卡包</param>
    /// <param name="miniPacks">随机的 4 个小卡包</param>
    public CardPool(BlockPack mainPack, MiniPack[] miniPacks) {
        MainPack = mainPack;
        SelectedMiniPacks = miniPacks;
        BuildPool();
    }

    private void BuildPool() {
        var seenNames = new HashSet<string>();

        // 主卡包优先
        AddBlockDefs(MainPack?.BlockDefs, seenNames);

        // 小卡包补充
        if (SelectedMiniPacks != null) {
            foreach (var mini in SelectedMiniPacks) {
                AddBlockDefs(mini?.BlockDefs, seenNames);
            }
        }
    }

    private void AddBlockDefs(BlockDef[] defs, HashSet<string> seenNames) {
        if (defs == null) {
            return;
        }

        foreach (var def in defs) {
            if (def == null) {
                continue;
            }

            if (def.BlockName != null && !seenNames.Add(def.BlockName)) {
                continue; // 已存在，跳过重复
            }

            _allBlockDefs.Add(def);
        }
    }

    /// <summary>
    ///     检查指定的 BlockName 是否在卡池中。
    /// </summary>
    public bool Contains(string blockName) {
        return _allBlockDefs.Any(b => b.BlockName == blockName);
    }

    /// <summary>
    ///     检查指定的 BlockDef 是否在卡池中。
    /// </summary>
    public bool Contains(BlockDef blockDef) {
        return blockDef != null && _allBlockDefs.Contains(blockDef);
    }

    /// <summary>
    ///     从卡池中随机获取一个 BlockDef，用于战利品奖励等场景。
    ///     如果卡池为空则返回 null。
    /// </summary>
    public BlockDef GetRandomBlockDef() {
        if (_allBlockDefs.Count == 0) {
            return null;
        }

        var index = Glob.GetMiscRand(_allBlockDefs.Count);
        return _allBlockDefs[index];
    }

    /// <summary>
    ///     从卡池中随机获取多个不重复的 BlockDef。
    ///     如果请求数量超过卡池大小，则返回卡池中所有 BlockDef（打乱顺序）。
    /// </summary>
    /// <param name="count">要获取的数量</param>
    /// <param name="excludeNames">要排除的 BlockName 集合</param>
    public List<BlockDef> GetRandomBlockDefs(int count, HashSet<string> excludeNames = null) {
        var candidates = _allBlockDefs
            .Where(b => excludeNames == null || !excludeNames.Contains(b.BlockName))
            .ToList();

        // 打乱候选列表
        var shuffled = new List<BlockDef>(candidates);
        var n = shuffled.Count;
        while (n > 1) {
            n--;
            var k = Glob.GetMiscRand(n + 1);
            (shuffled[k], shuffled[n]) = (shuffled[n], shuffled[k]);
        }

        return shuffled.Take(count).ToList();
    }
}
