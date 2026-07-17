#region

using Godot;

#endregion

/// <summary>
///     小卡包，包含 10 个 BlockDef。
///     每局游戏会从多个小卡包中随机选择 4 个，与玩家选择的主卡包共同构成卡池。
///     小卡包用于增加每局游戏的多样性和不可预测性。
/// </summary>
[GlobalClass]
public partial class MiniPack : Resource {
    /// <summary>
    ///     小卡包名称，用于 UI 显示和标识。
    /// </summary>
    [Export]
    public string PackName { get; set; }

    /// <summary>
    ///     小卡包中包含的 BlockDef 列表，固定 10 个。
    ///     这些小卡包为每局游戏注入变化，使同一角色在不同对局中拥有不同的可用 Block。
    /// </summary>
    [Export]
    public BlockDef[] BlockDefs { get; set; } = [];
}
