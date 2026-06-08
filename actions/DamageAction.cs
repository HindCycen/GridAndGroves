#region

using Godot;

#endregion

/// <summary>
///     伤害动作。对标 StS 的 DamageAction。
///     执行流程：
///     1. duration > 0 时：每帧 TickDuration（在此期间播放攻击 VFX）
///     2. duration 归零时：对目标造成实际伤害
///     依次触发：
///     - Stat 的 OnBeforeDamageApply（可修改 Amount）
///     - HealthComponent.TakeDamage()
///     - Stat 的 OnAfterDamageApply
///     3. 标记 IsDone = true
/// </summary>
public class DamageAction : AbstractGameAction {
    /// <summary>
    ///     创建一个伤害动作。
    /// </summary>
    /// <param name="source">伤害来源节点</param>
    /// <param name="target">伤害目标节点</param>
    /// <param name="damage">基础伤害值</param>
    /// <param name="duration">动作持续时长（秒），默认 0.3f</param>
    public DamageAction(Node source, Node target, int damage, float duration = 0.3f)
        : base(duration) {
        Source = source;
        Target = target;
        Amount = damage;
        ActionType = Glob.ActionType.Damage;
    }

    /// <summary>实际伤害值。可在 PreDamage 钩子中被修改。</summary>
    public int DamageAmount {
        get => Amount;
        set => Amount = value;
    }

    public override void Update(float delta) {
        if (IsDone) {
            return;
        }

        // duration > 0 阶段：播放 VFX，等时间流逝
        TickDuration(delta);
        if (!IsDone) {
            return;
        }

        // ─── duration 归零：执行实际伤害 ───

        // Step 1: 触发 OnBeforeDamageApply 钩子（可修改 Amount）
        TriggerBeforeDamageHooks();

        // Step 2: 播放伤害数字 VFX
        PlayDamageVFX();

        // Step 3: 找到目标并扣血
        var targetHealth = FindTargetHealth();
        if (targetHealth != null) {
            targetHealth.TakeDamage(Amount);
        }

        // Step 4: 触发 OnAfterDamageApply 钩子
        TriggerAfterDamageHooks();
    }

    /// <summary>
    ///     播放浮动伤害数字 VFX。
    /// </summary>
    private void PlayDamageVFX() {
        var targetNode = Target as Node2D;
        if (targetNode == null && Source != null) {
            var enemies = Source.GetTree()?.GetNodesInGroup("Enemies");
            targetNode = enemies?.Count > 0 ? enemies[0] as Node2D : null;
        }

        if (targetNode != null && GodotObject.IsInstanceValid(targetNode)) {
            var vfx = new DamageNumberVFX(targetNode.GlobalPosition, Amount);
            var tree = targetNode.GetTree();
            tree?.CurrentScene?.AddChild(vfx);
        }
    }

    private void TriggerBeforeDamageHooks() {
        TriggerDamageHooks(Glob.StatExecuteAt.OnBeforeDamageApply);
    }

    private void TriggerAfterDamageHooks() {
        TriggerDamageHooks(Glob.StatExecuteAt.OnAfterDamageApply);
    }

    private void TriggerDamageHooks(Glob.StatExecuteAt period) {
        if (Source == null) {
            return;
        }

        var statsComponents = Source.GetTree()?.GetNodesInGroup("stats_components");
        if (statsComponents == null) {
            return;
        }

        foreach (var node in statsComponents) {
            if (node is StatsComponent sc) {
                foreach (var stat in sc.GetAllStatuses()) {
                    stat.Definition?.Behavior?.ExecuteAt(period);
                }
            }
        }
    }

    private HealthComponent FindTargetHealth() {
        if (Target is Node2D targetNode) {
            var hc = GetHealthComponent(targetNode);
            if (hc != null) {
                return hc;
            }
        }

        return FindFirstAliveEnemyHealth();
    }

    private static HealthComponent GetHealthComponent(Node2D node) {
        return node.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
    }

    private HealthComponent FindFirstAliveEnemyHealth() {
        if (Source == null) {
            return null;
        }

        var tree = Source.GetTree();
        if (tree == null) {
            return null;
        }

        foreach (var enemy in tree.GetNodesInGroup("Enemies")) {
            if (enemy is not Node2D e) {
                continue;
            }

            var hc = GetHealthComponent(e);
            if (hc != null && !hc.IsDead) {
                return hc;
            }
        }

        return null;
    }
}