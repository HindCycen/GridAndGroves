# Grid and Groves - AI Coding Agent Instructions

## Project Overview

**Grid and Groves** is a Godot 4.6 C# game combining grid-based puzzle placement mechanics (7 columns × 5 rows grid) with roguelike/battle elements. The core gameplay involves dragging and placing blocks composed of multiple parts onto an unlockable grid, then executing them in turn-based combat.

## Architecture

### Core Structure

```
script/
├── core/
│   ├── blocks/          # Block placement and behavior system
│   │   ├── Block.cs     # Main block entity (drag-droppable)
│   │   ├── BlockPart.cs # Individual clickable units composing a block
│   │   ├── BlockDef.cs  # Block definition (Resource container)
│   │   ├── BlockPartDef.cs # BlockPart definition with behaviors
│   │   ├── BlockPartBehavior.cs # Behavior interface for extensibility
│   ├── actors/          # Combat entities and utilities
│   │   ├── Actor.cs     # Combat entity (HP, Shield, damage/heal)
│   │   ├── ActorBase.cs # Base class with MaxHP
│   │   ├── Player.cs    # Player subclass of Actor
│   │   ├── Enemy.cs     # Enemy combat unit
│   │   ├── EnemyDef.cs  # Enemy definition (Resource)
│   │   ├── EnemyTurnDef.cs # Resource describing enemy block pools/turns
│   │   ├── BattleController.cs # Lightweight enemy turn helper (attached to Enemy)
│   │   ├── HealthStat.cs # HP management component
│   │   └── ShieldStat.cs # Shield/absorption component
│   └── battle/          # Turn-based battle flow
│       ├── Battle.cs    # Main battle scene script
│       ├── BattleContext.cs # Signal hub (turn coordination)
│       └── Bot.cs       # AI controller for player/enemy
├── global/              # Global game state and utilities (under `script/global`)
│   ├── Global.cs        # Base abstract class for static utilities
│   ├── GlobalBlockInitializer.cs # Block registry and factory replacement
│   ├── GlobalGridControlling.cs # Grid state management (7×5 indexed)
│   ├── GlobalGridSizeConstants.cs # Pixel/grid constants
│   ├── GlobalRandSetter.cs # Seeded RNG for reproducibility
│   └── GlobalConstants.cs # GridState enum
resources/               # Game data and behavior resources (top-level)
├── blockpart_behaviors/ # Custom BlockPartBehavior implementations (.cs/.tres)
└── blockparts/          # Block and part definition .tres files
assets/                  # Sprites and imported assets
scenes/                  # Packed scenes used by the game (actors, battle, blocks)
```

### Data Flow

1. **Initialization** (Main.cs → Global):
   - `Global.InitRng()` - Seeds all RNG streams
   - `Global.InitGrids()` - Initializes grid points and states

2. **Block Creation**:
   - Definitions are registered via `Global.SubscribeBlockDef(blockDef)` (often
     in a `Battle` or `Main` scene `_initializeBlocks()` method).
   - Blocks are instantiated at runtime with
     `Global.GetBlock("BlockName", position, parent)` which loads
     `Block.tscn`, sets `Definition`, and adds it to the scene tree.
   - The newly created block automatically builds its `BlockPart` children and
     positions them using `BlockPartDef.PartialPosition * GridSize`.
   - The legacy `BlockFactory` class was removed; the global registry replaces
     its functionality.

3. **Placement Workflow**:
   - User clicks BlockPart → emits `Pressed` signal to parent Block
   - Block follows mouse while `IsPressed && !IsPlaced` (via `_Process`)
   - On release: checks validation conditions
     - `CheckConditionP()`: all parts within grid bounds (pixel area)
     - `CheckConditionQ()`: all parts snap to free grid cells (no collision)
     - `CheckConditionR()`: block root position within grid bounds
   - If all valid: snaps to nearest grid point, marks cells as `Occupied`, sets `IsPlaced = true`

## Critical Patterns

### Block Composition

- **One Block = Multiple BlockParts**: A `Block` is a container; `BlockParts` are clickable/interactive units (see `Block.LoadParts()`)
- **Position Calculation**: Part position = `PartDefinition.PartialPosition * GridSize` (additive to parent Block position)
- **Signals Over Direct Calls**: BlockParts emit `Pressed`/`Released` signals; Block listens for state changes

### Grid System

- **7×5 Grid** indexed by `[col, row]`: stored in `Global.GridPoints[col, row]` (7 columns, 5 rows)
- **GridStates enum**: `Free` (available), `Unable` (locked row/col), `Occupied` (placed block)
- **Row/Col Locking**: `UnlockedRows[5]` and `UnlockedCols[7]` control available placement areas via `InitUnlockedState()`
- **Default Unlocked**: Rows [1,2,3], Cols [1,2,3,4,5] (outer rows [0,4] and outer cols [0,6] disabled by default)
- **Grid Bounds**: `GridLeftUp = (240, 480)px`, `GridRightDown = (912, 960)px` (pixel coordinates)

### RNG for Determinism

- Five isolated RNG streams (map, monster, reward, chest, misc) seeded from single `_currentSeed`
- All RNG methods use `RandiRange(0, scope-1)` pattern
- Enables replay/testing with fixed seeds

### BlockPartBehavior Extension Pattern

- Behaviors are polymorphic `Resource` instances attached to `BlockPartDef.Behaviors[]`
- Executed via `BlockPart.Execute(Block owner)` which calls `behavior.Execute(Block, BlockPart)` for each behavior
- New behaviors inherit from `BlockPartBehavior`, implement `Execute(Block owner, BlockPart part)` abstract method
- Example: `ExamplePartBehavior.cs` in `resources/blockpart_behaviors/`

## Code Conventions

- **Namespace**: Classes in global namespace (no `namespace GridandGroves` explicit)
- **Visibility**: Mix of `private` and public fields; use `[Export]` for editor-linked Godot properties
- **Signal Names**: PascalCase with `EventHandler` suffix (e.g., `PressedEventHandler`)
- **Static Utilities**: Implemented as abstract partial classes in `Global` base (e.g., `GlobalGridControlling`)
- **Resource Definitions**: Separate `*Def` classes inherit from Godot `Resource` for serialization

### Battle System & Signal Flow

- `BattleContext.cs` emits signals: `BattleContextReady`, `BattleStarted`, `TurnStarted`, `TurnEnded`, `BattleEnded`, `TicTac`
- `Battle.cs` (or `Main.cs`) registers block definitions and spawns blocks
  using `Global.GetBlock` rather than a `BlockFactory` node.
- Blocks listen to `BattleContext` signals to coordinate lifecycle (subscribe in `_Ready`)
- Turn lifecycle: `TurnStarted` → block execution phase → `TurnEnded` → cleanup

## Integration Points

### Godot Node Tree

- `Battle` or `Main` scene is responsible for subscribing block definitions and
  may call `Global.GetBlock(...)` to spawn them; there is no `BlockFactory` node
- `BlockPart` instances auto-initialize `Area2D` + collision shape + sprite in `_Ready()`
- `BattleContext` added to scene groups for signal discovery

### External Dependencies

- **Godot 4.6**: C# bindings (export, signals, node hierarchy, partial classes)
- **Godot.NET.Sdk 4.5.1**: .NET 8.0 (net9.0 on Android target)
- No external NuGet packages beyond Godot SDK

## Development Workflow

### Common Tasks

1. **Adding Block Types**:
   - Create a `.tres` `BlockDef` resource in `resources/blockparts/`.
   - Create associated `BlockPartDef` resources with `SpriteTexture`,
     `PartialPosition`, optional `Behaviors[]` and other properties.
   - Load and subscribe the definition during scene initialization with
     `Global.SubscribeBlockDef(GD.Load<BlockDef>("res://resources/blockdefs/Your.tres"))`.
   - Instantiate blocks at runtime via `Global.GetBlock("YourName", pos, this)`.
   - The sample `Battle.cs` shows `ExampleBlock.tres` and
     `ExampleMoveRight.tres` being registered and spawned.

2. **Implementing Behaviors**:
   - Add a new class inheriting `BlockPartBehavior` under
     `resources/blockpart_behaviors/`.
   - Override `Execute(Block owner, BlockPart part)` with your custom logic.
   - Link the behavior asset to a `BlockPartDef.Behaviors[]` array in the editor.

3. **Working with Actors and Stats**:
   - Use `HealthStat` and `ShieldStat` nodes on `Actor` instances for
     hitpoints and shield mechanics. Call `ApplyDamage`, `Heal`, etc.
   - Enemy data is described by `EnemyDef` and `EnemyTurnDef` resources; load
     them to configure enemy behavior loops.

4. **Testing Placement Logic**:
   - Modify `CheckConditionP()`, `CheckConditionQ()`, or `CheckConditionR()` in
     `Block.cs` to tweak validity rules.

5. **Grid Tweaks**:
   - Adjust pixel constants in `GlobalGridSizeConstants.cs` (PxSize=120,
     GridSize=96, HalfGridSize=48) or modify unlocked rows/columns via
     `GlobalGridControlling` methods.

### Build/Run

- Build as Godot C# project: `dotnet build` or F5 in Godot editor
- Main scene: `uid://dowu1ejcjyr7i` (Main.tscn or Battle.tscn)
- Window: 960×540 display, 1920×1080 internal viewport (2× scaling)
- Initialize game state: Always call `Global.InitRng()` then `Global.InitGrids()` in `_Ready()`

## Areas Under Development

- Block behavior execution and resolution phase (turn order, damage application) continues
  to be a focus; `ExecutingDamage*` behaviors are early examples.
- Roguelike progression: monster/reward systems referenced in RNG but UI/balance
  not implemented; enemy definitions (`EnemyDef` / `EnemyTurnDef`) are scaffolding.
- Grid unlock progression mechanics (roguelike dungeon flow, dynamic row/col unlocking)
  remain a planned feature.
- Enemy AI and turn-based combat resolution are primitive; `Bot.cs` and
  `BattleController` exist but are minimal.
- Comprehensive behavior validation and chaining (multiple effects per part) need
  polish and testing.

---

**Last Updated**: 2026-02-27 | **Godot Version**: 4.6 | **Runtime**: .NET 8.0+ | **Grid**: 7×5 cells
