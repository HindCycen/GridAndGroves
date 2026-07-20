class_name GridPartSlotDef extends Resource
## Grid 中一个部件槽位的静态数据定义
##
## 描述了一个部件在 Grid 内的相对位置、贴图引用、数值和行为。
## 由 GridDefLoader 从 JSON 解析生成。

## 相对于 Grid 原点的位置（整数坐标，单位：格子数）
var position: Vector2i
## 贴图 ID，对应 GridPartPicture.id
var picture_id: String
## 伤害数值
var damage: int
## 护盾数值
var shield: int
## 魔法数字（非攻防数值的通用字段，由具体行为解释）
var magic_number: int
## 行为类名，如 "DamageBehavior"、"ShieldBehavior"
## 运行时通过 ClassDB.instantiate(behavior_id) 创建行为实例
var behavior_id: String
