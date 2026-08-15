class_name BlockPartBehavior extends Resource

func create_action(_block, _part):
	return null

func prevents_clear() -> bool:
	return false

## 通用放置限制钩子（默认放行）。需要限制放置位置的 Behavior 覆写此方法
## （如"只能放网格正中央"）。Block._check_placement_conditions 会遍历部件
## behaviors 调用本方法，任一返回 false 则不允许放置。
func check_placement(_block: Block) -> bool:
	return true
