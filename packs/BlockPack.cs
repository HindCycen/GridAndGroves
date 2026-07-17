#region

using Godot;

#endregion

/// <summary>
///     卡包（大卡包），包含 30~35 个 BlockDef。
///     玩家在开局时从多个卡包中选择一个作为本局的主卡包。
///     每个角色对应一个卡包，构成角色的核心卡池。
/// </summary>
[GlobalClass]
public partial class BlockPack : Resource {
    /// <summary>
    ///     卡包名称，用于 UI 显示和标识。
    /// </summary>
    [Export]
    public string PackName { get; set; }

    /// <summary>
    ///     卡包中包含的 BlockDef 列表，建议 30~35 个。
    ///     这些 Block 构成了角色本局游戏的核心可用 Block。
    /// </summary>
    [Export]
    public BlockDef[] BlockDefs { get; set; } = [];
}
