using Godot;
using System;

public partial class Enemy : Actor {
    [Export] public EnemyDef Definition;

    public override void _Ready() {
        HP = Definition.MaxHP;
        Shield = Definition.StartingShield;
    }
}
