class_name GridDef extends Resource
## 一个方块的静态数据定义 — 由 GridDefLoader 从 JSON 解析生成
##
## 包含方块的所有部件排列信息、显示名称和特殊标记。
## 运行时通过 GridLibrary.get_grid_def(id) 获取。

## 方块唯一标识符
var id: String
## 显示名称（UI 用）
var display_name: String
## 特殊标记（如 "permanent" 表示回合结束不清除）
var special_tag: String
## 部件槽位列表，每个槽位定义了一个部件的位置、贴图、数值和行为
var parts: Array  # Array[GridPartSlotDef]
