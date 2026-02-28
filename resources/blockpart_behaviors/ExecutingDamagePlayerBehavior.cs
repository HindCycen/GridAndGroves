using Godot;
using System;

public partial class ExecutingDamagePlayerBehavior : BlockPartBehavior {
    public override void Execute(Block block, BlockPart part) {
        foreach (var player in part.GetTree().GetNodesInGroup("Players")) {
            if (player is Player p) {
                p.TakeDamage(part.PartDefinition.Damage);
            }
        }
    }
}