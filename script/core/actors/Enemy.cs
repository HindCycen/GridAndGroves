using Godot;
using System;

public partial class Enemy : Actor {
    [Export] public EnemyDef Definition;

    public override void _Ready() {
        // Let ActorBase create stat components first
        base._Ready();

        // Override with EnemyDef values
        if (Definition != null) {
            HealthStat.Initialize(Definition.MaxHP);
            ShieldStat.AddShield(Definition.StartingShield);
        }
    }
}