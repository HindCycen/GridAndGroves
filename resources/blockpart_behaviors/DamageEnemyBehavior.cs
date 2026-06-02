using Godot;

/// <summary>
/// 对全体敌人造成伤害。CreateAction 返回 DamageAction 以支持时长和 VFX。
/// </summary>
[GlobalClass]
public partial class DamageEnemyBehavior : BlockPartBehavior {
    public override void Execute(Block block, BlockPart part) {
        var damage = part.Damage;
        if (damage <= 0) return;

        GD.Print($"DamageEnemyBehavior: 造成 {damage} 点伤害！");
        var enemies = block.GetTree().GetNodesInGroup("Enemies");
        foreach (var node in enemies) {
            if (node is not Node2D enemy) continue;
            var healthComponent = enemy.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (healthComponent != null) {
                healthComponent.TakeDamage(damage);
                GD.Print($"  对 {enemy.Name} 造成 {damage} 点伤害，剩余 HP: {healthComponent.CurrentHealth}/{healthComponent.MaxHealth}");
            }
        }
    }

    public override AbstractAction CreateAction(Block block, BlockPart part) {
        var tree = block.GetTree();
        if (tree == null) return base.CreateAction(block, part);

        var enemies = tree.GetNodesInGroup("Enemies");
        Node target = null;
        foreach (var enemy in enemies) {
            if (enemy is Node2D e) {
                var hc = e.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
                if (hc != null && !hc.IsDead) {
                    target = e;
                    break;
                }
            }
        }

        // 每个 DamageAction 作用一个敌人
        // 如果只有一个敌人，直接返回单体 DamageAction
        if (target != null) {
            return new DamageAction(block, target, part.Damage, 0.4f);
        }

        // 旧式兼容
        return base.CreateAction(block, part);
    }
}
