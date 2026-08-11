class_name LooseBlockBehavior extends BlockPartBehavior

## 松动 (Loose) Behavior —— 标记类
## Block 被触发后立即释放占用的网格格子，Block 进入弃牌堆而非销毁
## 是铁锈游侠的核心机制：高频腾挪 + 资源循环
##
## 注意：此 Behavior 本身不返回 Action。
## 实际松动逻辑由 Bot / ResonanceBot 在检测到本标记后统一执行
## （_process_block_part → _loose_block → BlockPilesHere.send_block_to_discard）。

func create_action(_block, _part):
	# 松动处理由 Bot 统一执行，避免双重处理
	return null
