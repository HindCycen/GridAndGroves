class_name DataResource extends Resource

@export var ChestRandUsage: int
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
