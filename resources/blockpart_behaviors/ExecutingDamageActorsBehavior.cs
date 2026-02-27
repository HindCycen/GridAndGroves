using Godot;
using System;

public partial class ExecutingDamageActorsBehavior : BlockPartBehavior {
    override public void Execute(Block block, BlockPart part) {
        foreach(var actor in part.GetTree().GetNodesInGroup("Actors")){
            if(actor is Actor a){
                a.TakeDamage(part.PartDefinition.Damage);
            }
        }
    }
}
