#region

using Godot;

#endregion

[GlobalClass]
public partial class DamagePlayerBehavior : BlockPartBehavior {
    public override void Execute(Block block, BlockPart part) {
        var damage = part.PartDefinition.Damage;
        if (damage <= 0) return;

        GD.Print($"DamagePlayerBehavior: 对玩家造成 {damage} 点伤害！");

        var players = block.GetTree().GetNodesInGroup("Players");
        foreach (var node in players) {
            if (node is not Node2D player) continue;

            var healthComponent = player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (healthComponent != null) {
                healthComponent.TakeDamage(damage);
                GD.Print($"  对玩家造成 {damage} 点伤害，剩余 HP: {healthComponent.CurrentHealth}/{healthComponent.MaxHealth}");
            }
        }
    }
}
