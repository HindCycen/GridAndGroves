using Godot;

public partial class GrowingStatBehavior : StatBehavior {
    [StatusBehavior(Period = Glob.StatExecuteAt.OnBattleEnded)]
    public void HealPlayer() {
        var stat = BelongingStat;
        if (stat == null) return;
        var tree = stat.GetTree();
        if (tree == null) return;
        var players = tree.GetNodesInGroup("Players");
        foreach (var node in players) {
            if (node is not Node2D player) continue;
            var healthComponent = player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (healthComponent != null) {
                healthComponent.Heal(12);
                GD.Print($"GrowingStatBehavior: 回复 12 点生命，当前 HP: {healthComponent.CurrentHealth}/{healthComponent.MaxHealth}");
            }
        }
    }
}
