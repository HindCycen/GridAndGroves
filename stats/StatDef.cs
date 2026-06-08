#region

using Godot;

#endregion

[GlobalClass]
public partial class StatDef : Resource {
    [Export] public StatBehavior Behavior;
    [Export] public bool CanGoNegative;
    [Export] public string Description;
    [Export] public Texture2D Icon;
    [Export] public int MaxValue;
    [Export] public string StatName;

    /// <summary>
    ///     战斗结束时自动移除该状态。
    ///     用于药水等临时效果（true = 药水效果，false = 遗物常驻效果）。
    /// </summary>
    [Export] public bool RemoveOnBattleEnd;
}