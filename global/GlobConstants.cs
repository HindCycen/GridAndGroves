public partial class Glob {
    /// <summary>
    ///     动作类型枚举，用于 ActionQueue 的行为分类
    /// </summary>
    public enum ActionType {
        Damage,
        Block,
        ApplyStatus,
        RemoveStatus,
        Heal,
        Wait,
        VFX,
        Callback,
        ModifyDirection,
        Special
    }

    public enum GridState {
        Free,
        Unable,
        Occupied
    }

    /// <summary>
    ///     面向 StatBehavior 的触发时机枚举。
    ///     每个值代表 ActionQueue 执行管线中的一个钩子点。
    /// </summary>
    public enum StatExecuteAt {
        // === 房间级 ===
        OnBattleStarted,
        OnBattleEnded,
        OnTurnStarted,
        OnTurnEnded,

        // === TicTac 三段式 ===
        /// Phase A: 在 BlockPart.Execute() 之前触发，可用于修饰数值
        OnPreBlockExecute,

        /// Phase B: 在 BlockPart.Execute() 期间触发（由 Part 自己的 Behavior 产生 Action）
        OnBlockExecute,

        /// Phase C: 在 BlockPart.Execute() 之后触发，可用于"造成伤害后"类效果
        OnPostBlockExecute,

        // === 伤害管线（由 DamageAction 在内部触发） ===
        /// 修改"即将造成的伤害"（atDamageGive 等效）
        OnBeforeDamageApply,

        /// 在伤害实际生效后触发（onAttack 等效）
        OnAfterDamageApply,

        /// 修改"即将获得的格挡"
        OnBeforeBlockApply,

        /// 在格挡实际生效后触发
        OnAfterBlockApply,

        /// 状态被施加时触发
        OnStatusApplied
    }

    /// <summary>
    ///     对应于尖塔"打出一张牌"事件的三个阶段。
    ///     PreBlockExecute → BlockExecute → PostBlockExecute
    ///     每个阶段产生的 Action 按序进入 ActionQueue。
    /// </summary>
    public enum TicTacPhase {
        PreBlockExecute, // Phase A: 前置修饰、扣费、atDamageGive 类
        BlockExecute, // Phase B: BlockPart 自身的 Execute()
        PostBlockExecute // Phase C: 后置触发、onAttack、荆棘类
    }
}