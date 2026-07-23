class_name BlockDef extends Resource

## Block 定义 Resource
## Faction: 0=Player, 1=Enemy — 决定 Block 默认所属阵营

enum BlockFactionDef { Player, Enemy }

@export var BlockName: String
@export var Description: String
@export var Faction: int = BlockFactionDef.Player
@export var PartDefinitions: Array
