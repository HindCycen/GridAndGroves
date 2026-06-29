#region

using Godot;

#endregion

[GlobalClass]
public partial class StageDef : Resource {
    [Export] public StageEnemyChartDef StageEnemyChart;
    [Export] public EventRand StageEventRand;

    /// <summary>
    ///     新游戏时的初始牌组（Block 名称列表）。
    ///     为 null 或空数组时使用 BattleRoom 中的硬编码默认牌组。
    /// </summary>
    [Export] public string[] StartingDeck;
}