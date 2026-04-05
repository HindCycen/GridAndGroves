#region

using Godot;
using System.Collections.Generic;
using System.Linq;

#endregion

public partial class StatsComponent : Node {
    [Signal]
    public delegate void StatusAddedEventHandler(string statusName, int currentValue, int maxValue);
    
    [Signal]
    public delegate void StatusRemovedEventHandler(string statusName);
    
    [Signal]
    public delegate void StatusChangedEventHandler(string statusName, int currentValue, int maxValue);
    
    private readonly Dictionary<string, Stat> _statusMap = new();
    private readonly List<Stat> _statusList = new();
    private readonly Dictionary<string, Stat.ValueChangedEventHandler> _eventHandlers = new();
    
    public int StatusCount => _statusList.Count;
    
    public override void _Ready() {
        AddToGroup("stats_components");
    }
    
    private void OnStatValueChanged(string statusName, int current, int max) {
        EmitSignal(SignalName.StatusChanged, statusName, current, max);
    }
    
    /// <summary>
    /// 添加一个新的状态
    /// </summary>
    public void AddStatus(Stat stat) {
        if (stat == null) {
            GD.PrintErr("尝试添加空状态");
            return;
        }
        
        string statusName = stat.Definition.StatName;
        if (_statusMap.ContainsKey(statusName)) {
            GD.PrintErr($"状态 {statusName} 已存在");
            return;
        }
        
        _statusMap[statusName] = stat;
        _statusList.Add(stat);
        AddChild(stat);
        
        var handler = new Stat.ValueChangedEventHandler((current, max) => OnStatValueChanged(statusName, current, max));
        _eventHandlers[statusName] = handler;
        stat.ValueChanged += handler;
        
        EmitSignal(SignalName.StatusAdded, statusName, stat.CurrentValue, stat.Definition.MaxValue);
    }
    
    /// <summary>
    /// 移除一个状态
    /// </summary>
    public void RemoveStatus(string statusName) {
        if (!_statusMap.ContainsKey(statusName)) {
            GD.PrintErr($"状态 {statusName} 不存在");
            return;
        }
        
        Stat stat = _statusMap[statusName];
        if (_eventHandlers.TryGetValue(statusName, out var handler)) {
            stat.ValueChanged -= handler;
            _eventHandlers.Remove(statusName);
        }
        
        _statusMap.Remove(statusName);
        _statusList.Remove(stat);
        stat.QueueFree();
        
        EmitSignal(SignalName.StatusRemoved, statusName);
    }
    
    /// <summary>
    /// 获取指定名称的状态
    /// </summary>
    public Stat GetStatus(string statusName) {
        return _statusMap.TryGetValue(statusName, out var stat) ? stat : null;
    }
    
    /// <summary>
    /// 获取所有状态
    /// </summary>
    public IReadOnlyList<Stat> GetAllStatuses() {
        return _statusList.AsReadOnly();
    }
    
    /// <summary>
    /// 检查是否存在某个状态
    /// </summary>
    public bool HasStatus(string statusName) {
        return _statusMap.ContainsKey(statusName);
    }
    
    /// <summary>
    /// 清空所有状态
    /// </summary>
    public void ClearAllStatuses() {
        foreach (var statusName in _statusMap.Keys.ToList()) {
            RemoveStatus(statusName);
        }
    }
}