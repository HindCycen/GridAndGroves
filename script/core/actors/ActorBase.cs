using Godot;
using System;

public partial class ActorBase : Node2D {
    [Export] public int MaxHP = 100;

    private HealthStat _healthStat;
    private ShieldStat _shieldStat;

    /// <summary> Health stat component </summary>
    public HealthStat HealthStat => _healthStat;

    /// <summary> Shield stat component </summary>
    public ShieldStat ShieldStat => _shieldStat;

    /// <summary> Current HP (delegates to HealthStat) </summary>
    public int HP {
        get => _healthStat?.HP ?? 0;
        set {
            if (_healthStat != null) {
                _healthStat.HP = value;
            }
        }
    }

    /// <summary> Current Shield (delegates to ShieldStat) </summary>
    public int Shield {
        get => _shieldStat?.Shield ?? 0;
        set {
            if (_shieldStat != null) {
                _shieldStat.Shield = value;
            }
        }
    }

    public override void _Ready() {
        // Create stat components
        _healthStat = new HealthStat { Name = "HealthStat" };
        _shieldStat = new ShieldStat { Name = "ShieldStat" };

        AddChild(_healthStat);
        AddChild(_shieldStat);

        // Initialize health
        _healthStat.HealthChanged += OnHealthChanged;
        _healthStat.Initialize(MaxHP);
        _healthStat.OnDie = Die;

        // Initialize shield
        _shieldStat.ShieldChanged += OnShieldChanged;
        _shieldStat.ResetShield();
    }

    /// <summary> Apply damage (handles shield and HP reduction) </summary>
    public virtual void TakeDamage(int damage) {
        bool isDead = _healthStat.ApplyDamage(damage, _shieldStat);
        GD.Print($"{Name} took {damage} damage. HP: {HP}, Shield: {Shield}");
    }

    /// <summary> Heal the actor </summary>
    public virtual void Heal(int amount) {
        _healthStat.Heal(amount);
        GD.Print($"{Name} healed {amount}. HP: {HP}");
    }

    /// <summary> Add shield </summary>
    public virtual void ShieldUp(int amount) {
        _shieldStat.AddShield(amount);
        GD.Print($"{Name} shielded up. Shield: {Shield}");
    }

    /// <summary> Called when actor dies </summary>
    protected virtual void Die(ActorBase actor) {
        GD.Print($"{Name} has died.");
    }

    protected virtual void OnHealthChanged(int currentHP, int changeAmount, int maxHP) {
        // Override in derived classes for custom behavior on health change
    }

    protected virtual void OnShieldChanged(int currentShield, int changeAmount) {
        // Override in derived classes for custom behavior on shield change
    }
}
