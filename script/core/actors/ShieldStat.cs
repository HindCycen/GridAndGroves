using Godot;
using System;

public partial class ShieldStat : Node {
    private int _shield = 0;

    /// <summary> Current shield value </summary>
    public int Shield {
        get => _shield;
        set => _shield = Mathf.Max(0, value);
    }

    /// <summary> Increase shield </summary>
    public void AddShield(int amount) {
        Shield += amount;
    }

    /// <summary> Absorb damage with shield, returns remaining damage </summary>
    public int AbsorbDamage(int damage) {
        if (Shield >= damage) {
            Shield -= damage;
            return 0;
        }
        else {
            int remaining = damage - Shield;
            Shield = 0;
            return remaining;
        }
    }

    /// <summary> Reset shield to 0 </summary>
    public void ResetShield() {
        Shield = 0;
    }
}
