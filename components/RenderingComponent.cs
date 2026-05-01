#region

using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Godot;

#endregion

public partial class RenderingComponent : Control {
    private readonly Dictionary<string, StatIcon> _statIcons = new();
    private HBoxContainer _statsContainer;
    [Export] public int BarLength;
    [Export] public int StatIconPx = 45;

    public StatsComponent StatsComponent { get; private set; }

    public override void _Ready() {
        StatsComponent = GetNode<StatsComponent>("%StatsComponent");
        _statsContainer = GetNode<HBoxContainer>("%StatsContainer");

        StatsComponent.StatusAdded += OnStatusAdded;
        StatsComponent.StatusRemoved += OnStatusRemoved;
    }

    private void OnStatusAdded(string name, int current, int max) {
        var stat = StatsComponent.GetStatus(name);
        if (stat == null) {
            return;
        }

        var icon = new StatIcon();
        icon.Setup(stat, StatIconPx);
        _statIcons[name] = icon;
        _statsContainer.AddChild(icon);
    }

    private void OnStatusRemoved(string name) {
        if (_statIcons.TryGetValue(name, out var icon)) {
            icon.Detach();
            _statIcons.Remove(name);
            icon.QueueFree();
        }
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
        return StatsComponent.GetAllStatuses().ToArray();
    }
}