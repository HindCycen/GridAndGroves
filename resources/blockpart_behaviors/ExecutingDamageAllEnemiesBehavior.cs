using Godot;
using System;

public partial class ExecutingDamageAllEnemiesBehavior : BlockPartBehavior{
    public override void Execute(Block owner, BlockPart part) {
        foreach (var enemy in part.GetTree().GetNodesInGroup("Enemies")) {
            if (enemy is Enemy e) {
                e.TakeDamage(part.PartDefinition.Damage);
            }
        }
    }
}
