#region

using System;
using Godot;

#endregion

[GlobalClass]
public partial class HealthComponent : Node {
    [Signal]
    public delegate void DiedEventHandler();

    [Signal]
    public delegate void HealthChangedEventHandler(int current, int max);

    /// <summary>伤害被护盾吸收时触发。参数：(absorbed, remainingDamage)</summary>
    [Signal]
    public delegate void ShieldAbsorbedEventHandler(int absorbed, int remaining);

    [Export] public int MaxHealth { get; private set; } = 100;

    [Export] public int CurrentHealth { get; private set; }
    public bool IsDead => CurrentHealth <= 0;

    public override void _Ready() {
        CurrentHealth = MaxHealth;
    }

    /// <summary>
    ///     对角色造成伤害。先消耗护盾（如果有），剩余伤害扣除生命值。
    /// </summary>
    public void TakeDamage(int damage) {
        if (damage < 0) {
            throw new ArgumentException("伤害值不能为负数");
        }

        if (damage == 0) {
            return;
        }

        // ── 优先消耗护盾 ──
        var shield = ResolveShieldComponent();
        if (shield != null && shield.CurrentShield > 0) {
            var absorbed = Math.Min(shield.CurrentShield, damage);
            shield.ReduceShield(absorbed);
            damage -= absorbed;
            EmitSignal(SignalName.ShieldAbsorbed, absorbed, damage);
        }

        // ── 剩余伤害扣血 ──
        if (damage > 0) {
            CurrentHealth = Math.Max(0, CurrentHealth - damage);
        }

        EmitSignal(SignalName.HealthChanged, CurrentHealth, MaxHealth);

        if (IsDead) {
            EmitSignal(SignalName.Died);
        }
    }

    public void Heal(int amount) {
        if (amount < 0) {
            throw new ArgumentException("治疗值不能为负数");
        }

        CurrentHealth = Math.Min(MaxHealth, CurrentHealth + amount);
        EmitSignal(SignalName.HealthChanged, CurrentHealth, MaxHealth);
    }

    public void SetMaxHealth(int value) {
        if (value <= 0) {
            throw new ArgumentException("最大生命值必须大于0");
        }

        MaxHealth = value;
        CurrentHealth = Math.Min(CurrentHealth, MaxHealth);
        EmitSignal(SignalName.HealthChanged, CurrentHealth, MaxHealth);
    }

    public void SetCurrentHealth(int value) {
        if (value < 0) {
            throw new ArgumentException("当前生命值不能为负数");
        }

        CurrentHealth = Math.Min(value, MaxHealth);
        EmitSignal(SignalName.HealthChanged, CurrentHealth, MaxHealth);
    }

    /// <summary>
    ///     向上遍历场景树查找 ShieldComponent。
    ///     玩家有 ShieldComponent，敌人一般没有。
    /// </summary>
    private ShieldComponent ResolveShieldComponent() {
        // 先尝试直接使用 % 唯一名称查找（同场景内）
        var shield = GetNodeOrNull<ShieldComponent>("%ShieldComponent");
        if (shield != null) return shield;

        // 向上遍历
        var parent = GetParent();
        while (parent != null) {
            shield = parent.GetNodeOrNull<ShieldComponent>("%ShieldComponent");
            if (shield != null) return shield;
            parent = parent.GetParent();
        }

        return null;
    }
}
