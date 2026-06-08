# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Grid and Groves** is a roguelike deck-building game built with Godot 4.6+ (Mono/C#) and .NET 8.0. The game is heavily inspired by Slay the Spire — players place polyomino-like blocks on a grid, which a patrol bot then walks over to trigger effects against enemies.

## Build & Run

- **Open project**: Launch Godot 4.6+, open the project root directory
- **Run**: Press F5 in the Godot editor
- **Build**: Godot handles compilation via the .NET SDK; `dotnet build` also works from CLI
- **Solution**: `Grid and Groves.sln` / `Grid and Groves.csproj` (targets `net8.0`, Android targets `net9.0`)

## Architecture

### Autoloads (Global Singletons)

Three autoloads are registered in `project.godot`:

| Autoload | Type | Role |
|----------|------|------|
| `Glob` | `Glob` (partial class) | Central hub: grid state, RNG streams, block registry, factory methods. Split across `global/Glob*.cs` files |
| `BattleTime` | `BattleTime` | Event bus — emits battle lifecycle signals (TurnStarted, PreBlockExecute, BlockExecute, PostBlockExecute, TurnEnded, BattleStarted, BattleEnded). Each signal auto-triggers matching StatBehavior hooks |
| `SaveLoad` | `SaveLoad` | Persists/restores game state via `DataResource` (a Godot `.tres` Resource) |

### ActionQueue System

Modeled after StS `AbstractGameAction`/`GameActionManager`. All game effects are async actions enqueued in `ActionQueue`:

- **`AbstractAction`** (`actions/`): base class with `Duration`, `Update(float delta)`, `TickDuration()`, `IsDone`. Subclasses: `DamageAction`, `HealAction`, `ApplyStatusAction`, `CallbackAction`, `WaitAction`, `VFXAction`
- **`ActionQueue`** (`actions/ActionQueue.cs`): singleton FIFO queue, processes one action per frame. `AddToBottom()` (normal) / `AddToTop()` (priority). Exists as a child node of `BattleRoom`

### Bot Patrol (Core Combat Loop)

`Bot.cs` patrols the 7×5 grid in snake pattern, 1 cell per second. Each tick is a 3-phase "TicTac":

1. **Phase A — `SayPreBlockExecute()`**: Stat hooks for pre-block modifiers (e.g., +damage)
2. **Phase B — `MoveToNextCell()` → `EnqueueBlockActionsAt()`**: Bot moves; if it lands on a cell occupied by a Block, all `BlockPartBehavior.CreateAction()` results are enqueued into ActionQueue. The Part's `MovingDirection` changes the Bot's patrol direction
3. **Phase C — `SayPostBlockExecute()`**: Stat hooks for on-hit triggers (thorns, etc.)

When Bot reaches grid boundary → `EndTurn()` → enemy attacks → new player turn.

### Block System (Content Creation Pipeline)

Blocks are composed from Resources and scene instances:

```
BlockDef (.tres) ──references──▶ BlockPartDef[] (.tres) ──references──▶ BlockPartBehavior[] (.cs code)
```

- **`BlockDef`** (Resource): name, description, list of `BlockPartDef`
- **`BlockPartDef`** (Resource): base damage/shield/magic, `MovingDirection` (patrol direction change), position in block, sprite, array of `BlockPartBehavior`
- **`BlockPartBehavior`** (abstract Resource): `CreateAction(block, part)` returns an `AbstractAction` for the queue
- **`Block`** (Node2D scene): runtime instance, handles drag-and-drop placement on grid, emits `Placed`/`LeftGrid` signals
- **`BlockPart`** (Node2D): runtime instance, handles click detection, tooltip display
- Register new blocks in `OriginalBlockRegisterer.Register()` via `Glob.SubscribeBlockDef()`

### Stat System

Stats are persistent buffs/debuffs displayed in the status bar. Uses reflection-based attribute hooks:

- **`StatDef`** (Resource): name, max value, icon, whether it can go negative, bound `StatBehavior`
- **`Stat`** (Node): runtime instance with `CurrentValue`, `AddValue()`/`ReduceValue()`/`SetValue()`. Auto-registers to `"stats"` group
- **`StatBehavior`** (abstract Resource): methods decorated with `[StatusBehavior(Period = Glob.StatExecuteAt.XXX)]` are auto-discovered via reflection and invoked by `BattleTime` signals
- **`StatsComponent`** (Node): manages a collection of `Stat` nodes on an actor, emits `StatusAdded`/`StatusChanged`/`StatusRemoved`

Full list of `StatExecuteAt` trigger points: `OnBattleStarted`, `OnBattleEnded`, `OnTurnStarted`, `OnTurnEnded`, `OnPreBlockExecute`, `OnBlockExecute`, `OnPostBlockExecute`, `OnBeforeDamageApply`, `OnAfterDamageApply`, `OnBeforeBlockApply`, `OnAfterBlockApply`, `OnStatusApplied`

### Room Hierarchy

```
Room (base: health bar, save/load)
├── CountedRoom (increments RoomCount on enter)
│   ├── BattleRoom (combat, ActionQueue, Bot, turn management)
│   └── EventRoom (narrative events with choices)
└── UncountedRoom (doesn't increment RoomCount)
    └── StageRoom (14×7 floor map grid, navigation)
```

### Card Flow (In-Battle)

`BlockPilesHere` manages four piles: `DrawPile` → `ShowingPile` (hand, 3 cards) → `PlacedPile` (on grid) → `DiscardedPile`. Draw pile empty → reshuffle discard. Player places blocks by drag-and-drop onto the 7×5 grid.

### RNG & Save System

Six independent RNG streams (`MapRand`, `MonsterRand`, `RewardRand`, `ChestRand`, `MiscRand`, `PileRand`) all seeded from a single master seed. Usage counts are tracked so save/load can deterministically replay RNG calls to restore state. `SaveLoad` syncs between `DataResource` fields and in-game state (player health, deck composition, floor map, stats).

### Key File Locations

| System | Path |
|--------|------|
| Action base/queue | `actions/` |
| Block defs/parts/behaviors | `blocks/`, `resources/blockdefs/`, `resources/blockparts/`, `resources/blockpart_behaviors/` |
| Stat defs/behaviors | `resources/stat_defs/`, `resources/stat_behaviors/` |
| Glob partials | `global/Glob*.cs` |
| Rooms | `room/` |
| Components (Health, AI, Stats, etc.) | `components/` |
| Actors (Player, Enemy) | `actors/player/`, `actors/enemy/` |
| VFX | `vfx/` |
| Attributes | `attributes/` |
| Registerers | `registerers/` |
| Content docs | `docs/如何制作BlockAndStat内容.md` |
| Stat behavior docs | `stats/STAT_BEHAVIOR_SYSTEM.md` |
| Floor loop docs | `docs/StageRoom.md` |

### Content Creation Pattern

To add a new block:
1. Write `BlockPartBehavior` subclass in `resources/blockpart_behaviors/` (override `CreateAction()`)
2. Create `BlockPartDef.tres` in `resources/blockparts/` via Godot editor, configure behaviors/damage/direction
3. Create `BlockDef.tres` in `resources/blockdefs/`, reference the PartDef
4. Register in `OriginalBlockRegisterer.Register()` with `Glob.SubscribeBlockDef()`

To add a new stat:
1. Write `StatBehavior` subclass with `[StatusBehavior(Period = ...)]` decorated methods
2. Create `StatDef.tres` in `resources/stat_defs/`, set behavior and max value
3. Apply via `StatsComponent.AddStatus(stat)`
