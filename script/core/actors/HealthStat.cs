using Godot;
using System;

public partial class HealthStat : Node {
    private int _maxHP = 100;
    private int _hp = 100;

    /// <summary> Current HP value </summary>
    public int HP {
        get => _hp;
        set => _hp = Mathf.Clamp(value, 0, _maxHP);
    }

    /// <summary> Maximum HP value </summary>
    public int MaxHP {
        get => _maxHP;
        set {
            _maxHP = Mathf.Max(1, value);
            if (_hp > _maxHP) {
                _hp = _maxHP;
            }
        }
    }

    /// <summary> Callback when actor dies </summary>
    public Action<ActorBase> OnDie { get; set; }

    /// <summary> Initialize health with maxHP </summary>
    public void Initialize(int maxHP) {
        MaxHP = maxHP;
        HP = maxHP;
    }

    /// <summary> Apply damage, returns true if actor dies </summary>
    public bool ApplyDamage(int damage, ShieldStat shield) {
        int remainingDamage = damage;

        // Shield absorbs damage first
        if (shield != null) {
            remainingDamage = shield.AbsorbDamage(remainingDamage);
        }

        // Remaining damage goes to HP
        if (remainingDamage > 0) {
            HP -= remainingDamage;
        }

        // Check if dead
        if (HP <= 0) {
            OnDie?.Invoke(GetParent<ActorBase>());
            return true;
        }

        return false;
    }

    /// <summary> Heal the actor </summary>
    public void Heal(int amount) {
        HP += amount;
    }

    /// <summary> Reset HP to max </summary>
    public void ResetHP() {
        HP = MaxHP;
    }
}
