using Godot;
using System;

public abstract partial class Actor : ActorBase {
    public int Shield { get; protected set; }

    public override void _Ready() {
        HP = MaxHP;
        Shield = 0;
    }

    public virtual void TakeDamage(int damage) {
        int remainingDamage = damage;

        if (Shield > 0) {
            if (Shield >= remainingDamage) {
                Shield -= remainingDamage;
                remainingDamage = 0;
            }
            else {
                remainingDamage -= Shield;
                Shield = 0;
            }
        }

        if (remainingDamage > 0) {
            HP -= remainingDamage;
            if (HP < 0) {
                HP = 0;
                Die();
            }

        }

        GD.Print($"{Name} took {damage} damage. HP: {HP}, Shield: {Shield}");
    }

    public virtual void Heal(int amount) {
        HP += amount;
        if (HP > MaxHP) {
            HP = MaxHP;
        }
        GD.Print($"{Name} healed {amount}. HP: {HP}");
    }

    public virtual void ShieldUp(int amount) {
        Shield += amount;
        GD.Print($"{Name} shielded up. Shield: {Shield}");
    }

    protected override void Die() {
        GD.Print($"{Name} has died.");
    }
}
