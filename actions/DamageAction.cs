using System.Linq;
using Godot;

/// <summary>
/// 伤害动作。对标 StS 的 DamageAction。
///
/// 执行流程：
/// 1. duration > 0 时：每帧 TickDuration（在此期间播放攻击 VFX）
/// 2. duration 归零时：对目标（敌人）造成实际伤害
///    依次触发：
///    - Stat 的 OnBeforeDamageApply（可修改 Amount）
///    - HealthComponent.TakeDamage()
///    - Stat 的 OnAfterDamageApply
/// 3. 标记 IsDone = true
/// </summary>
public class DamageAction : AbstractAction {
    /// <summary>实际伤害值。可在 PreDamage 钩子中被修改。</summary>
    public int DamageAmount {
        get => Amount;
        set => Amount = value;
    }

    /// <summary>是否跳过 VFX（连续伤害时用）</summary>
    private readonly bool _skipEffect;

    public DamageAction(Node source, Node target, int damage, float duration = 0.3f, bool skipEffect = false)
        : base(duration) {
        Source = source;
        Target = target;
        Amount = damage;
        ActionType = Glob.ActionType.Damage;
        _skipEffect = skipEffect;
    }

    public override void Update(float delta) {
        if (IsDone) return;

        // duration > 0 阶段：播放 VFX，等时间流逝
        TickDuration(delta);
        if (!IsDone) return;

        // ─── duration 归零：执行实际伤害 ───

        // Step 1: 触发 OnBeforeDamageApply 钩子（可修改 Amount）
        TriggerBeforeDamageHooks();

        // Step 2: 播放伤害数字 VFX
        PlayDamageVFX();

        // Step 3: 找到目标敌人并扣血
        var targetHealth = FindTargetHealth();
        if (targetHealth != null) {
            targetHealth.TakeDamage(Amount);
        }

        // Step 4: 触发 OnAfterDamageApply 钩子
        TriggerAfterDamageHooks();
    }

    /// <summary>
    /// 播放浮动伤害数字 VFX。
    /// </summary>
    private void PlayDamageVFX() {
        Node2D targetNode = Target as Node2D;
        if (targetNode == null && Source != null) {
            var enemies = Source.GetTree()?.GetNodesInGroup("Enemies");
            targetNode = enemies?.Count > 0 ? enemies[0] as Node2D : null;
        }

        if (targetNode != null && GodotObject.IsInstanceValid(targetNode)) {
            var vfx = new DamageNumberVFX(targetNode.GlobalPosition, Amount);
            // 直接添加到场景，自管理生命周期
            var tree = targetNode.GetTree();
            tree?.CurrentScene?.AddChild(vfx);
        }
    }

    private void TriggerBeforeDamageHooks() {
        if (Source == null) return;
        var statsComponents = Source.GetTree()?.GetNodesInGroup("stats_components");
        if (statsComponents == null) return;

        foreach (var node in statsComponents) {
            if (node is StatsComponent sc) {
                foreach (var stat in sc.GetAllStatuses()) {
                    stat.Definition?.Behavior?.ExecuteAt(Glob.StatExecuteAt.OnBeforeDamageApply);
                }
            }
        }
    }

    private void TriggerAfterDamageHooks() {
        if (Source == null) return;
        var statsComponents = Source.GetTree()?.GetNodesInGroup("stats_components");
        if (statsComponents == null) return;

        foreach (var node in statsComponents) {
            if (node is StatsComponent sc) {
                foreach (var stat in sc.GetAllStatuses()) {
                    stat.Definition?.Behavior?.ExecuteAt(Glob.StatExecuteAt.OnAfterDamageApply);
                }
            }
        }
    }

    private HealthComponent FindTargetHealth() {
        // 如果 Target 是 Enemy 或 Player
        if (Target is Node2D targetNode) {
            var hc = targetNode.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
            if (hc != null) return hc;
        }

        // 回退：在所有敌人中找第一个活的
        if (Source != null) {
            var tree = Source.GetTree();
            if (tree != null) {
                var enemies = tree.GetNodesInGroup("Enemies");
                foreach (var enemy in enemies) {
                    if (enemy is Node2D e) {
                        var hc = e.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
                        if (hc != null && !hc.IsDead) return hc;
                    }
                }
            }
        }

        return null;
    }
}
