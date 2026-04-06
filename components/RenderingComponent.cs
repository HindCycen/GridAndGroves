#region

using System.Diagnostics;
using System.Linq;
using Godot;

#endregion

public partial class RenderingComponent : Control {
    [Export] public int BarLength;
    [Export] public int StatIconPx;

    public override void _Ready() {
        // What to do here? 
    }

    public int GetHealth() {
        var hc = GetNode("%HealthComponent") as HealthComponent;
        Debug.Assert(hc != null, nameof(hc) + " != null");
        return hc.CurrentHealth;
    }

    public int GetDefend() {
        var dc = GetNode("%DefendComponent") as DefendComponent;
        Debug.Assert(dc != null, nameof(dc) + " != null");
        return dc.CurrentDefend;
    }

    public Stat[] GetStat() {
        var sc = GetNode("%StatsComponent") as StatsComponent;
        Debug.Assert(sc != null, nameof(sc) + " != null");
        return sc.GetAllStatuses().ToArray();
    }
}