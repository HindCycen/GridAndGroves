class_name DataResource extends Resource

@export var ChestRandUsage: int
@export var Gold: int = 10
@export var GridClickable: Array[int] = []
@export var GridIsBattleCell: Array[int] = []
@export var GridLeft: Array[int] = []
@export var MapRandUsage: int
@export var MiscRandUsage: int
@export var MonsterRandUsage: int
@export var PileRandUsage: int
@export var PlayerCurrentHealth: int
@export var PlayerDeckBlockNames: Array[String] = []
@export var PlayerMaxHealth: int
@export var PlayerStatNames: Array[String] = []
@export var PlayerStatValues: Array[int] = []
@export var RewardRandUsage: int
@export var RoomCount: int
@export var Seed: int
@export var StageCount: int
@export var StageDefPath: String
@export var LastNonStageRoomType: int = 0  # 0=None, 1=Battle, 2=Event
@export var LastNonStageRoomEventDefPath: String = ""
@export var LastNonStageRoomEnemyNames: Array[String] = []
@export var MainPackName: String = ""
@export var SelectedMiniPackNames: Array[String] = []
@export var KillCount: int = 0
## 当前所在房间类型（见 Enums.RoomType：0=Stage 1=Battle 2=Event 3=Shop）
## 用于 Continue 时恢复现场（Boss 商店/战斗中途退出不再丢流程）
@export var CurrentRoomType: int = 0
@export var CurrentRoomIsBossShop: bool = false
@export var CurrentRoomIsBossCell: bool = false
@export var CurrentRoomEnemyNames: Array[String] = []
@export var CurrentRoomEventPath: String = ""
## 地图返回按钮指向的上一场战斗是否为终点 Boss 格
@export var LastNonStageRoomIsBossCell: bool = false
