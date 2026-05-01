using Godot;

public partial class ShootingStatBehavior : StatBehavior {
    [StatusBehavior(Period = Glob.StatExecuteAt.OnTurnEnded)]
    public void ShootPlayer() {
        var stat = BelongingStat;
        if (stat == null) return;
        var tree = stat.GetTree();
        if (tree == null) return;
        var players = tree.GetNodesInGroup("Players");
        foreach (var node in players) {
            if (node is not Node2D player) continue;
            var healthComponent = player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (healthComponent != null) {
                healthComponent.TakeDamage(10);
                GD.Print($"ShootingStatBehavior: 对玩家造成 10 点伤害，剩余 HP: {healthComponent.CurrentHealth}/{healthComponent.MaxHealth}");
            }
        }
    }
}
