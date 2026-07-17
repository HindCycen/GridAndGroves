# 翠绿哨兵 (Verdant Sentinel)

> *"在 AI 封锁区生活的丛林之子，懂得如何与变异植物共生。他用藤蔓和孢子作为武器，耐心等待猎物自己倒下。"*

**定位**: 防守反击、持续伤害、控制战场
**关键资源**: 扎根 Block 的占格位置、藤蔓层数
**风格**: 用扎根 Block 长期占据网格，每回合提供稳定收益；藤蔓和共生效果随回合数增长滚雪球。

---

## 新机制

| 机制 | 说明 |
|------|------|
| **扎根 (Root)** | Block 留在网格上不消失（`PreventsClear = true`），每回合被 Bot 触发时提供效果。最多同时存在 3 个扎根 Block。扎根与铁锈游侠的"松动"形成鲜明对比。 |
| **藤蔓 (Vine)** | 新 Stat，施加于敌人。每回合结束时造成 层数 × 3 伤害，然后层数 -1（类似 StS 中毒）。层数随回合自然衰减，需要持续补充。 |
| **共生 (Symbiosis)** | 全局效果：场上**每有 1 个己方 Block**（含扎根和普通 Block），获得额外加成。与"松动"卡组配合时收益较低（Block 来去匆匆），与"扎根"卡组配合时收益极高。 |

## 新增 Stat

| StatDef | 触发时机 | 效果 |
|---------|----------|------|
| `VineStat` | `OnTurnEnded` | 每层对敌人造成 3 伤害 → 层数 -1 |
| `SymbiosisStat` | `OnPostBlockExecute` | 统计场上己方 Block 数 → 每有 1 个获得护盾 |

## 示例 Block

```
Block: "荆棘射击" (Thorn Shot)            [普通]
  部件1 @ (0, 0): 伤害 6，方向向下
    行为: DamageEnemyBehavior

Block: "缠绕藤蔓" (Entangling Vine)       [普通]
  部件1 @ (0, 0): —，方向向下
    行为: ApplyVineBehavior（3 层）

Block: "深根" (Deep Root)                 [稀有]
  部件1 @ (0, 0): 护盾 4，方向向下
    行为: GrantShieldBehavior
  特性: 驻留（PreventsClear = true），每回合提供 4 护盾

Block: "孢子云" (Spore Cloud)             [稀有]
  部件1 @ (0, 0): 伤害 2，方向向下
    行为: DamageEnemyBehavior
  额外: 对所有敌人施加 2 层 Vine

Block: "光合作用" (Photosynthesis)        [稀有]
  部件1 @ (0, 0): 治疗 5，方向向下
    行为: HealBehavior
  条件: 场上有 ≥ 2 个扎根 Block 时触发

Block: "荆棘反甲" (Thorned Armor)         [稀有]
  部件1 @ (0, 0): 护盾 10，方向向下
    行为: GrantShieldBehavior
  额外: 获得护盾时对敌人造成 3 伤害（反伤）

Block: "剧毒爆发" (Toxic Bloom)           [史诗]
  部件1 @ (0, 0): 伤害 4，方向向下
    行为: DamageEnemyBehavior
  额外: 消耗所有 Vine 层数，每层造成 2 额外伤害

Block: "丛林之怒" (Jungle's Wrath)        [稀有]
  部件1 @ (0, 0): 伤害 5，方向向下
    行为: DamageEnemyBehavior
  额外: 场上每有 1 个己方 Block，伤害 +2（共生）

Block: "种子地雷" (Seed Mine)             [史诗]
  部件1 @ (0, 0): 伤害 12，方向向下
    行为: DamageEnemyBehavior
  特性: 驻留（不消失直到被 Bot 触发，触发后爆炸并消失）

Block: "共生护盾" (Symbiotic Shield)      [稀有]
  部件1 @ (0, 0): 护盾 6，方向向下
    行为: GrantShieldBehavior
  部件2 @ (1, 0): 护盾 4，方向向下
    行为: GrantShieldBehavior
  额外: 场上每有 1 个己方 Block，所有护盾值 +1（共生）
```

## 卡包构成

| 类别 | 数量 |
|------|------|
| 藤蔓类 | ~5 |
| 扎根类 | ~4 |
| 共生类 | ~5 |
| 基础填充 | ~16 |
| **总计** | **~30** |

| 稀有度 | 数量 |
|--------|------|
| 普通 | ~15 |
| 稀有 | ~11 |
| 史诗 | ~4 |
| 传说 | ~0 |
