class_name ResonanceTriggerBehavior extends BlockPartBehavior

## 共鸣触发 (Resonance Trigger) Behavior
## 星语术士核心机制：标记 Block 为共鸣源
## 被触发时递归触发相邻的共鸣 Block（链式传播）
## 最多传播 3 层深度

## 注意：此 Behavior 不直接返回 Action，而是通过 Bot 的 _enqueue_block_actions_at
## 在触发时检测到 ResonanceTriggerBehavior 后执行递归共鸣逻辑
## 详细实现在 Bot.gd 的 _process_block_part 扩展中

## 此文件作为标记类存在，Bot 通过 `behavior is ResonanceTriggerBehavior` 来判断

func create_action(_block, _part):
	# 共鸣 Behavior 本身不返回 Action
	# 实际共鸣连锁逻辑在 Bot.gd 中实现
	return null
