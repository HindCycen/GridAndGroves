using Godot;
using System;

public partial class ActorBase : Node2D {
    [Export] public int MaxHP = 100;
    public int HP { get; protected set; }

    protected virtual void Die() {
        GD.Print($"{Name} has died.");
    }
}
