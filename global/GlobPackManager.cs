#region

using System.Collections.Generic;
using System.Linq;

#endregion

public partial class Glob {
    /// <summary>
    ///     所有已注册的主卡包（按 PackName 索引）。
    /// </summary>
    public static Dictionary<string, BlockPack> BlockPacks { get; } = [];

    /// <summary>
    ///     所有已注册的小卡包（按 PackName 索引）。
    /// </summary>
    public static Dictionary<string, MiniPack> MiniPacks { get; } = [];

    /// <summary>
    ///     当前局游戏的卡池。在游戏开始时构建，持续到游戏结束。
    /// </summary>
    public static CardPool CurrentCardPool { get; private set; }

    /// <summary>
    ///     注册一个主卡包，使其可以在游戏开局时被玩家选择。
    ///     如果名称已存在则注册失败并返回 false。
    /// </summary>
    public static bool SubscribeBlockPack(BlockPack pack) {
        if (pack == null) {
            GameLog.Err("PackManager: BlockPack is null");
            return false;
        }

        if (string.IsNullOrEmpty(pack.PackName)) {
            GameLog.Err("PackManager: BlockPack.PackName is null or empty");
            return false;
        }

        if (BlockPacks.ContainsKey(pack.PackName)) {
            GameLog.Err($"PackManager: BlockPack '{pack.PackName}' already registered");
            return false;
        }

        BlockPacks[pack.PackName] = pack;
        return true;
    }

    /// <summary>
    ///     注册一个小卡包，使其可以被选入本局游戏的卡池。
    ///     如果名称已存在则注册失败并返回 false。
    /// </summary>
    public static bool SubscribeMiniPack(MiniPack pack) {
        if (pack == null) {
            GameLog.Err("PackManager: MiniPack is null");
            return false;
        }

        if (string.IsNullOrEmpty(pack.PackName)) {
            GameLog.Err("PackManager: MiniPack.PackName is null or empty");
            return false;
        }

        if (MiniPacks.ContainsKey(pack.PackName)) {
            GameLog.Err($"PackManager: MiniPack '{pack.PackName}' already registered");
            return false;
        }

        MiniPacks[pack.PackName] = pack;
        return true;
    }

    /// <summary>
    ///     通过主卡包名称和随机选取的 4 个小卡包构建当前局的卡池。
    ///     如果小卡包总数不足 4 个，则使用所有可用小卡包。
    /// </summary>
    /// <param name="mainPackName">玩家选择的主卡包名称</param>
    /// <returns>构建成功返回 true，主卡包不存在返回 false</returns>
    public static bool BuildCardPool(string mainPackName) {
        if (!BlockPacks.TryGetValue(mainPackName, out var mainPack)) {
            GameLog.Err($"PackManager: BlockPack '{mainPackName}' not found");
            return false;
        }

        var availableMiniPacks = MiniPacks.Values.ToList();
        var selectedMiniPacks = new List<MiniPack>();

        // 如果可用小卡包数量 <= 4，全部选用
        if (availableMiniPacks.Count <= 4) {
            selectedMiniPacks.AddRange(availableMiniPacks);
        }
        else {
            // 随机选择 4 个（使用 Fisher-Yates 部分打乱）
            var pool = new List<MiniPack>(availableMiniPacks);
            var count = pool.Count;
            for (var i = 0; i < 4; i++) {
                var swapIdx = GetMiscRand(count - i) + i;
                (pool[i], pool[swapIdx]) = (pool[swapIdx], pool[i]);
                selectedMiniPacks.Add(pool[i]);
            }
        }

        CurrentCardPool = new CardPool(mainPack, selectedMiniPacks.ToArray());
        GameLog.Info(
            $"PackManager: CardPool built with main pack '{mainPackName}' " +
            $"and {selectedMiniPacks.Count} mini pack(s), total {CurrentCardPool.Count} BlockDefs"
        );
        return true;
    }

    /// <summary>
    ///     清除当前卡池（例如在游戏结束时调用）。
    /// </summary>
    public static void ClearCardPool() {
        CurrentCardPool = null;
        GameLog.Info("PackManager: CardPool cleared");
    }
}
