class_name EnemyDefinition extends Resource

@export var AttackDamage: int = 10
@export var EnemyName: String
@export var EnemyImage: Texture2D
@export var InitialStats: Array
## 与 InitialStats 平行的初始值数组（JSON 可选字段 initialStatValues）。
## 缺省时使用 StatDef.MaxValue。
@export var InitialStatValues: Array[int] = []
@export var IntentCycle: Array
@export var MaxHealth: int = 50
