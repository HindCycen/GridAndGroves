#region

using Godot;

#endregion

[GlobalClass]
public partial class DamageEnemyBehavior : BlockPartBehavior {
    public override void Execute(Block block, BlockPart part) {
        var damage = part.PartDefinition.Damage;
        if (damage <= 0) {
            return;
        }

        GD.Print($"DamageEnemyBehavior: 造成 {damage} 点伤害！");

        // 查找所有 Enemy 节点并造成伤害
        var enemies = block.GetTree().GetNodesInGroup("Enemies");
        foreach (var node in enemies) {
            if (node is not Node2D enemy) {
                continue;
            }

            // 通过路径找到 HealthComponent（在 RenderingComponent 下）
            var healthComponent = enemy.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (healthComponent != null) {
                healthComponent.TakeDamage(damage);
                GD.Print(
                    $"  对 {enemy.Name} 造成 {damage} 点伤害，剩余 HP: {healthComponent.CurrentHealth}/{healthComponent.MaxHealth}");
            }
        }
    }
}