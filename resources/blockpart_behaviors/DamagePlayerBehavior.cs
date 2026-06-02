using Godot;

/// <summary>
/// 对玩家造成伤害。CreateAction 返回 DamageAction。
/// </summary>
[GlobalClass]
public partial class DamagePlayerBehavior : BlockPartBehavior {
    public override void Execute(Block block, BlockPart part) {
        var damage = part.Damage;
        if (damage <= 0) return;

        GD.Print($"DamagePlayerBehavior: 对玩家造成 {damage} 点伤害！");
        var players = block.GetTree().GetNodesInGroup("Players");
        foreach (var node in players) {
            if (node is not Node2D player) continue;
            var healthComponent = player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (healthComponent != null) {
                healthComponent.TakeDamage(damage);
            }
        }
    }

    public override AbstractAction CreateAction(Block block, BlockPart part) {
        var tree = block.GetTree();
        var players = tree?.GetNodesInGroup("Players");
        Node target = players?.Count > 0 ? players[0] as Node2D : null;

        if (target != null) {
            return new DamageAction(block, target, part.Damage, 0.4f);
        }
        return base.CreateAction(block, part);
    }
}
