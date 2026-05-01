#region

using System.Collections.Generic;
using System.Reflection;
using Godot;

#endregion

[GlobalClass]
public partial class StatBehavior : Resource {
    private Stat _belongingStat;

    public Stat BelongingStat => _belongingStat;
    public StatExecuteMethod[] ExecuteMethods { get; private set; }

    public void SetBelongingStat(Stat statName) {
        _belongingStat = statName;
        CacheExecuteMethods();
    }

    private void CacheExecuteMethods() {
        var methods = GetType().GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        var executeList = new List<StatExecuteMethod>();

        foreach (var method in methods) {
            var attr = method.GetCustomAttribute<StatusBehaviorAttribute>();
            if (attr != null) {
                executeList.Add(new StatExecuteMethod {
                    Method = method,
                    ExecuteAt = attr.Period
                });
            }
        }

        ExecuteMethods = executeList.ToArray();
    }

    public void ExecuteAt(Glob.StatExecuteAt period) {
        if (ExecuteMethods == null) {
            return;
        }

        foreach (var exec in ExecuteMethods) {
            if (exec.ExecuteAt == period && exec.Method != null) {
                exec.Method.Invoke(this, null);
            }
        }
    }

    public struct StatExecuteMethod {
        public MethodInfo Method;
        public Glob.StatExecuteAt ExecuteAt;
    }
}