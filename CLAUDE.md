# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Grid and Groves** is a roguelike deck-building game built with Godot 4.6+ (Mono/C#) and .NET 8.0. The game is heavily inspired by Slay the Spire — players place polyomino-like blocks on a grid, which a patrol bot then walks over to trigger effects against enemies.

- **Root namespace**: `GridandGroves` (all files use the global default, no explicit namespace declarations)
- **Language split**: 60 C# source files (.cs) for game logic, 5 GDScript files (.gd) for UI/debug
- **Entry point**: `Main.tscn` / `Main.cs` (Node2D), which loads `Glob` as an autoload singleton
- **Reference material**: `foreign-influence/` contains decompiled Slay the Spire Java source (gitignored, not project code)

## Build & Run

- **Open project**: Launch Godot 4.6+, open the project root directory
- **Run**: Press F5 in the Godot editor
- **Build**: Godot handles compilation via the .NET SDK; `dotnet build` also works from CLI
- **Solution**: `Grid and Groves.sln` / `Grid and Groves.csproj` (targets `net8.0`, Android targets `net9.0`)
- **Export**: `export_presets.cfg` configured for Windows Desktop
- **Code style**: `.editorconfig` enforces K&R braces, 4-space indent for C#

## Project Statistics

- **C# source files**: 60 (across `actions/`, `actors/`, `attributes/`, `blocks/`, `components/`, `global/`, `registerers/`, `resources/`, `room/`, `stats/`, `vfx/`)
- **GDScript files**: 5 (UI/debug helpers in `actors/player/`, `components/`)
- **Scene files (.tscn)**: 16
- **Resource files (.tres)**: 27
- **Shader files (.gg)**: 2 (in `block_plan/`)

## Architecture

### Autoloads (Global Singletons)

Three autoloads are registered in `project.godot`:

| Autoload | Type | Role |
|----------|------|------|
| `Glob` | `Glob` (partial class, 7 files) | Central hub: grid state (7×5), RNG streams (6), block registry, factory methods, constants. Split across `global/Glob*.cs` files |
| `BattleTime` | `BattleTime` | Event bus — emits battle lifecycle signals (TurnStarted, PreBlockExecute, BlockExecute, PostBlockExecute, TurnEnded, BattleStarted, BattleEnded). Each signal auto-triggers matching StatBehavior hooks |
| `SaveLoad` | `SaveLoad` | Persists/restores game state via `DataResource` (a Godot `.tres` Resource) |

### Entry Point (`Main.tscn` / `Main.cs`)

The root scene `Main.tscn` references `Main.cs` (Node2D) which exports a `BlockDef[]` array of available block definitions. `Glob` auto-initializes as an autoload before `Main._Ready()`.

### ActionManager System

Modeled after StS `AbstractGameAction`/`GameActionManager`. All game effects are async actions enqueued in `ActionManager`:

- **`AbstractGameAction`** (`actions/AbstractGameAction.cs`): abstract base class with `Duration`, `StartDuration`, `Update(float delta)`, `TickDuration()`, `IsDone`. Key fields: `Amount` (generic int parameter), `Source` (Node), `Target` (Node), `ActionType` (enum), `ExhaustSourceBlock` (bool — if true, source Block is removed from combat after action resolves). Subclasses:
  - `DamageAction`, `HealAction`, `ApplyStatusAction`, `CallbackAction`, `WaitAction` — in `actions/`
  - `VFXAction` — in `vfx/`
- **`ActionManager`** (`actions/ActionManager.cs`): singleton FIFO queue (`Instance`), processes one action per frame via `_Process()`. `AddToBottom()` / `AddToTop()`. Zero-duration actions execute chained within the same frame (StS style). Exists as a child node of `BattleRoom`

### Bot Patrol (Core Combat Loop)

`Bot.cs` (`room/Bot.cs`) patrols the 7×5 grid in snake pattern, 1 cell per second. Each tick is a 3-phase "TicTac":

1. **Phase A — `SayPreBlockExecute()`**: Stat hooks for pre-block modifiers (e.g., +damage)
2. **Phase B — `MoveToNextCell()` → `EnqueueBlockActionsAt()`**: Bot moves; if it lands on a cell occupied by a Block, all `BlockPartBehavior.CreateAction()` results are enqueued into ActionManager. The Part's `MovingDirection` changes the Bot's patrol direction. If any action has `ExhaustSourceBlock == true`, the Block is immediately removed from play (no discard/reshuffle)
3. **Phase C — `SayPostBlockExecute()`**: Stat hooks for on-hit triggers (thorns, etc.)

When Bot reaches grid boundary → `EndTurn()` → enemy attacks (via `DamageAction` queue) → new player turn.

### Block System (Content Creation Pipeline)

Blocks are composed from Resources and scene instances:

```
BlockDef (.tres) ──references──▶ BlockPartDef[] (.tres) ──references──▶ BlockPartBehavior[] (.cs code)
```

- **`BlockDef`** (Resource): name, description, list of `BlockPartDef`
- **`BlockPartDef`** (Resource): base damage/shield/magic, `MovingDirection` (patrol direction change), position in block, sprite texture, array of `BlockPartBehavior`
- **`BlockPartBehavior`** (abstract Resource in `blocks/`): `CreateAction(block, part)` returns an `AbstractGameAction` for the queue. PreventsClear property — if true, block stays on grid across turns
- **`Block`** (Node2D scene): runtime instance, handles drag-and-drop placement on 7×5 grid, emits `Placed`/`LeftGrid` signals. Has `BlockFaction` enum (Player/Enemy) for faction-aware behavior
- **`BlockPart`** (Node2D): runtime instance, handles click detection, tooltip display
- **Block part behavior implementations** in `resources/blockpart_behaviors/`: `DamageEnemyBehavior`, `DamagePlayerBehavior`, `GrantShieldBehavior`, `GrantPlayerStatBehavior`, `GiveGrowingStatBehavior`, `MoveRightBehavior`, `DoNothing`, `ExamplePartBehavior`
- **Block bag resources**: `BlockBag` and `BigBlockBag` (in `resources/`) — structure blocks by rarity (Common/Uncommon/Rare)
- **`BlockPlacementDef`** (Resource in `resources/`): defines a Block + GridPosition + RandomOffsetRange for enemy-placed blocks

### Stat System

Stats are persistent buffs/debuffs displayed in the status bar. Uses reflection-based attribute hooks:

- **`StatDef`** (Resource in `stats/`): name, max value, icon texture, whether it can go negative, bound `StatBehavior`, and `RemoveOnBattleEnd` flag
- **`Stat`** (Node in `stats/`): runtime instance with `CurrentValue`, `AddValue()`/`ReduceValue()`/`SetValue()`. Auto-registers to `"stats"` group
- **`StatBehavior`** (abstract Resource in `stats/`): methods decorated with `[StatusBehavior(Period = Glob.StatExecuteAt.XXX)]` are auto-discovered via reflection and invoked by `BattleTime` signals
- **`StatsComponent`** (Node in `components/`): manages a collection of `Stat` nodes on an actor, emits `StatusAdded`/`StatusChanged`/`StatusRemoved`

Full list of `StatExecuteAt` trigger points: `OnBattleStarted`, `OnBattleEnded`, `OnTurnStarted`, `OnTurnEnded`, `OnPreBlockExecute`, `OnBlockExecute`, `OnPostBlockExecute`, `OnBeforeDamageApply`, `OnAfterDamageApply`, `OnBeforeBlockApply`, `OnAfterBlockApply`, `OnStatusApplied`

Stat behavior implementations in `resources/stat_behaviors/`: `ExampleStatBehavior`, `GrowingStatBehavior` (heal on battle end), `ShootingStatBehavior` (damage on turn end)

### Room Hierarchy

All rooms inherit from `Room` (Node2D) — there are no intermediate `CountedRoom`/`UncountedRoom` classes in the codebase. Room base handles: status bar (health display, stage/room count), automatic `RoomCount` increment on `_Ready()`, and `_ExitTree()` auto-save via `SaveLoad`.

```
Room (base: Node2D, health bar, save/load, room count)
├── BattleRoom (7×5 combat grid, ActionManager, Bot, turn management, enemy spawning)
├── EventRoom (narrative events with choices and outcomes)
└── StageRoom (14×7 floor map grid, navigation, battle/event room transitions)
```

#### BattleRoom
- Manages `BlockPilesHere`, `Bot`, `ActionManager`, enemies, turn lifecycle
- Player deck initialization (3 DamageBlock + 2 ExampleMoveRight + 2 ExampleBlock + 1 Growing + 1 Shield)
- Spawns enemies from `EnemyChartDef` (weak/strong/boss variants based on room count)
- Pile viewer buttons (抽牌堆/弃牌堆)
- Victory → transitions to StageRoom; Defeat → game over

#### EventRoom
- Displays event description and choice buttons (2-3 choices)
- Each `EventChoiceDef` has action type + value: HealPlayer, DamagePlayer, AddBlockToDeck, RemoveBlockFromDeck
- TooltipComponent hover descriptions on choices

#### StageRoom
- 14×7 floor map grid, snake-path traversal (clickable cells flash)
- Battle cells (randomly ~50%) → BattleRoom; Event cells → EventRoom
- Boss at room count 20; strong enemies after room 6; weak enemies before that
- Map state is saved/restored via `DataResource` arrays

### Block Pile / Card Flow (In-Battle)

`BlockPilesHere` (`room/BlockPilesHere.cs`) manages four `PileComponent` references:

- **`PileComponent`** (`components/PileComponent.cs`): reusable Node2D that holds a list of Block references with add/remove/random-access operations

Pile flow: `DrawPile` → `ShowingPile` (hand, 3 cards drawn per turn) → `PlacedPile` (placed on grid) → `DiscardedPile` (after turn clear). Draw pile empty → reshuffle discard. "Place one, draw one" rule — placing a block from ShowingPile triggers an immediate draw. Blocks with `PreventsClear` (via behavior property) stay on the grid across turns.

The Player has a `PlayerPile` (`%PlayerPile`) in `Player.tscn` which holds their persistent deck — this is copied into `DrawPile` at battle start.

### Enemy System

- **`Enemy.cs`** (`actors/enemy/`): Node2D with `EnemyDefinition` resource, `AttackDamage`, `AIComponent`
- **`AIComponent`** (`components/`): handles enemy turn execution — places blocks on grid using `IntentDefinition` cycle
- **`EnemyDefinition`** (Resource): name, max health, attack damage, image texture, initial stats, intent cycle
- **`IntentDefinition`** (Resource): defines what blocks the enemy places (via `BlockPlacementDef` array)
- **`EnemyChartDef`** (Resource): array of `EnemyDefinition` for a single battle encounter
- **`StageEnemyChartDef`** (Resource): contains WeakEnemyChart[], StrongEnemyChart[], BossChart[] — selected based on room count

### Shield System

- **`ShieldComponent`** (`components/`): node with `CurrentShield`/`MaxShield`, emits `ShieldChanged`. Shield resets to 0 on turn end (via `BattleTime.TurnEnded` signal)
- **`HealthComponent`** (`components/`): `TakeDamage()` first consumes shield via `ShieldComponent` lookup, then reduces health. Emits `Died`, `HealthChanged`, `ShieldAbsorbed` signals
- **`HealthBar`** (`components/HealthBar.cs`): `TextureProgressBar` subclass that listens to `HealthChanged` and `ShieldChanged` signals, updates visual bars (health + shield overlays)
- **`HealthLabel`** (`components/HealthLabel.cs`): Label subclass that displays "HP / MaxHP" text

### RenderingComponent

`RenderingComponent` (`components/RenderingComponent.cs`) is a `Control` node that acts as the visual container for each actor. It contains:
- `HealthComponent`, `ShieldComponent`, `StatsComponent` via `%` unique name references
- `StatIcon` instances for each active stat — dynamically created/removed as stats are added/removed

### RNG & Save System

Six independent RNG streams (`MapRand`, `MonsterRand`, `RewardRand`, `ChestRand`, `MiscRand`, `PileRand`) all seeded from a single master seed. Usage counts are tracked so save/load can deterministically replay RNG calls to restore state. `SaveLoad` syncs between `DataResource` fields and in-game state (player health, deck composition, floor map, stats).

`DataResource` (`resources/DataResource.cs`) stores: player health (current/max), room count, stage count, player deck block names, grid state arrays (clickable/left/isBattleCell), stats data.

### VFX System

- **`VFXAction`** (`vfx/VFXAction.cs`): `AbstractGameAction` subclass for visual-only effects
- **`DamageNumberVFX`** (`vfx/DamageNumberVFX.cs`): floating damage numbers
- **`BlockNumberVFX`** (`vfx/BlockNumberVFX.cs`): floating block/shield numbers

### Event System (Out-of-Battle)

- **`EventDef`** (Resource): event description text, array of `EventChoiceDef`
- **`EventChoiceDef`** (Resource): choice name, description, `EventActionType` (enum: HealPlayer/DamagePlayer/AddBlockToDeck/RemoveBlockFromDeck), action value, result description
- **`EventRand`** (Resource): array of possible `EventDef` references for random event selection
- **`StageDef`** (Resource): `StageEventRand` (EventRand) for stage-level event configuration

## Attributes

Two custom C# attributes in `attributes/`:
- `[BlockRegisterer]` — marks classes that register blocks (discovered by `GlobRegistererExecuter`)
- `[StatusBehavior(Period = ...)]` — marks methods on `StatBehavior` subclasses that auto-execute at specific battle lifecycle points

### GDScript Files

Five GDScript files exist for UI/debug purposes (not part of core C# architecture):
- `actors/player/ActorSprite.gd` — player actor sprite animation
- `components/BlockBox.gd` — block grid box UI element
- `components/HealthBox.gd` — health display box UI
- `components/MaxHealthBox.gd` — max health display box UI
- `components/TestThingsHere.gd` — test/debug helper

## Resource Files Summary (.tres)

All 27 `.tres` files by category:

| Category | Files | Path |
|----------|-------|------|
| Block Defs | `DamageBlock`, `EnemyAttackBlock`, `ExampleBlock`, `ExampleMoveRight`, `GrowingBlock`, `Shield`, `Strike` | `resources/blockdefs/` |
| Block Parts | `DamagePart00`, `Defend10`, `EnemyAttackPart00`, `ExampleBlockPart00/01`, `ExampleMoveRight00`, `GrowingPart00`, `Nothing00`, `Shield00/01`, `Strike01` | `resources/blockparts/` |
| Enemy Defs | `Gonh` (30 HP, 5 ATK) | `resources/enemy_defs/` |
| Enemy Intents | `PlaceAttackAtCenter`, `PlaceAttackRight` | `resources/enemy_intents/` |
| Stat Defs | `Growing`, `Shooting` | `resources/stat_defs/` |
| Stage/Event | `EgHealEvent`, `EgStageDef`, `EgStageEnemyChart` | `resources/` |

## Scene Files Summary (.tscn)

16 `.tscn` files: `Main.tscn`, `Actor.tscn`, `Enemy.tscn`, `Player.tscn`, `Block.tscn`, `Room.tscn`, `BattleRoom.tscn`, `EventRoom.tscn`, `StageRoom.tscn`, `AIComponent.tscn`, `HealthComponent.tscn`, `PileComponent.tscn`, `RenderingComponent.tscn`, `ShieldComponent.tscn`, `StatsComponent.tscn`, `Stat.tscn`

## Key File Locations

| System | Path |
|--------|------|
| Action base/queue | `actions/` |
| Block runtime classes | `blocks/` |
| Block defs (.tres) | `resources/blockdefs/` |
| Block parts (.tres) | `resources/blockparts/` |
| Block part behaviors (.cs) | `resources/blockpart_behaviors/` |
| Block part sprites | `resources/blockpart_picture/` (blue/green/grey subdirs) |
| Stat runtime classes | `stats/` |
| Stat defs (.tres) | `resources/stat_defs/` |
| Stat behaviors (.cs) | `resources/stat_behaviors/` |
| Stat images | `resources/stat_images/` |
| Glob partials | `global/Glob*.cs` (7 files) |
| Rooms | `room/` |
| Components (Health, Shield, AI, Stats, Pile, etc.) | `components/` |
| Actors (Player, Enemy) | `actors/player/`, `actors/enemy/` |
| VFX | `vfx/` |
| Attributes | `attributes/` |
| Registerers | `registerers/` |
| Enemy definitions (.tres) | `resources/enemy_defs/` |
| Enemy intents (.tres) | `resources/enemy_intents/` |
| Enemy images | `resources/enemy_images/` |
| Event config (.tres) | `resources/` (root) |
| Stage config (.tres) | `resources/` (root) |
| Room backgrounds | `room/battle_background/`, `room/room_pictures/` |
| Bot sprites | `room/bot_frames/` |
| Shader files | `block_plan/` |
| Documentation (Chinese) | `docs/`, `stats/STAT_BEHAVIOR_SYSTEM.md` |
| Dev notes | `prompts/` |

## Documentation Files

| File | Description |
|------|-------------|
| `docs/如何编写Resource文件.md` | Guide on writing Godot Resource .cs types and .tres files (Chinese) |
| `docs/如何制作BlockAndStat内容.md` | Guide on creating block and stat content with the ActionQueue system (Chinese) |
| `docs/StageRoom.md` | Floor loop system documentation (Room hierarchy, map, encounters) |
| `stats/STAT_BEHAVIOR_SYSTEM.md` | StatBehavior attribute-based auto-execution system design |

## Content Creation Pattern

### Add a new block:
1. Write `BlockPartBehavior` subclass in `resources/blockpart_behaviors/` (override `CreateAction()`)
2. Create `BlockPartDef.tres` in `resources/blockparts/` via Godot editor, configure behaviors/damage/direction/sprite
3. Create `BlockDef.tres` in `resources/blockdefs/`, reference the PartDef
4. Register in `OriginalBlockRegisterer.Register()` with `Glob.SubscribeBlockDef()`

### Add a new stat:
1. Write `StatBehavior` subclass with `[StatusBehavior(Period = ...)]` decorated methods
2. Create `StatDef.tres` in `resources/stat_defs/`, set behavior and max value
3. Apply via `StatsComponent.AddStatus(stat)`

### Add a new enemy:
1. Create `EnemyDefinition.tres` in `resources/enemy_defs/` (name, HP, attack, image, stats, intent cycle)
2. Create `IntentDefinition.tres` in `resources/enemy_intents/` (block placement patterns)
3. Add to an `EnemyChartDef` or `StageEnemyChartDef` for battle encounters
