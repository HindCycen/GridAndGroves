#region

using System.Collections.Generic;
using System.Linq;
using Godot;

#endregion

// ReSharper disable CheckNamespace
public partial class Block : Node2D {
    [Signal]
    public delegate void LeftGridEventHandler(Block block);

    [Signal]
    public delegate void PlacedEventHandler(Block block);

    public enum BlockFaction {
        Player,
        Enemy
    }

    public static bool InputLocked;

    private readonly List<BlockPart> _parts = [];
    private bool _wasOnGrid;
    [Export] public BlockDef Definition;
    public BlockFaction Faction = BlockFaction.Player;

    public bool IsPlaced;
    public bool IsPressed;
    public Vector2 OriginalPos;

    /// <summary>
    ///     返回当前方块所有部件的快照数组。
    /// </summary>
    public BlockPart[] GetParts() {
        return _parts.ToArray();
    }

    public override void _Ready() {
        OriginalPos = GlobalPosition;
        LoadParts();
    }


    public override void _Process(double delta) {
        if (IsPressed && !InputLocked && Faction == BlockFaction.Player) {
            GlobalPosition = GetGlobalMousePosition();
        }
    }

    private void LoadParts() {
        foreach (var def in Definition.PartDefinitions) {
            var part = CreatePart(def);
            if (part.HasSignal("Pressed")) {
                WirePartPressEvents(part);
            }
        }
    }

    private BlockPart CreatePart(BlockPartDef def) {
        var part = new BlockPart { PartDefinition = def };
        _parts.Add(part);
        AddChild(part);
        return part;
    }

    private void WirePartPressEvents(BlockPart part) {
        part.Pressed += OnPartPressed;
        part.Released += OnPartReleased;
    }

    private void OnPartPressed(Node n) {
        if (!_parts.Contains(n) || InputLocked || Faction != BlockFaction.Player) {
            return;
        }

        IsPressed = true;
        if (IsPlaced) {
            _wasOnGrid = true;
            LiftFromGrid();
        }
    }

    private void OnPartReleased(Node n) {
        if (!_parts.Contains(n) || InputLocked || Faction != BlockFaction.Player) {
            return;
        }

        IsPressed = false;
        if (CheckPlacementConditions()) {
            FinalizePlacement();
        }
        else if (_wasOnGrid) {
            _wasOnGrid = false;
            EmitSignalLeftGrid(this);
        }
        else {
            GlobalPosition = OriginalPos;
        }
    }

    private bool CheckPlacementConditions() {
        return AreAllPartsInGridBounds() && AreAllCellsFree() && IsCenterInGridBounds();
    }

    private void FinalizePlacement() {
        GlobalPosition = Glob.FindNearestGridPoint(GlobalPosition);
        OccupyAllPartGrids();
        _wasOnGrid = false;
        OriginalPos = GlobalPosition;
        IsPlaced = true;
        EmitSignalPlaced(this);
    }

    private void OccupyAllPartGrids() {
        foreach (var part in _parts) {
            var gridPoint = Glob.FindNearestGridPoint(part.GlobalPosition);
            var gridIndex = Glob.GetGridCoords(gridPoint);
            if (gridIndex.X >= 0 && gridIndex.Y >= 0) {
                Glob.SetGridState(gridIndex.X, gridIndex.Y, Glob.GridState.Occupied);
            }
        }
    }

    private void LiftFromGrid() {
        foreach (var part in _parts) {
            var gridPoint = Glob.FindNearestGridPoint(part.GlobalPosition);
            var gridIndex = Glob.GetGridCoords(gridPoint);
            if (gridIndex.X >= 0 && gridIndex.Y >= 0) {
                Glob.SetGridState(gridIndex.X, gridIndex.Y, Glob.GridState.Free);
            }
        }

        IsPlaced = false;
    }

    private bool AreAllPartsInGridBounds() {
        return _parts.All(part => Glob.IsPointInGrid(part.GlobalPosition));
    }

    private bool AreAllCellsFree() {
        foreach (var nearestGridPoint in _parts.Select(part => Glob.FindNearestGridPoint(part.GlobalPosition))) {
            if (!Glob.IsPointInGrid(nearestGridPoint)) {
                return false;
            }

            var gridIndex = Glob.GetGridCoords(nearestGridPoint);
            if (gridIndex.X < 0 || gridIndex.X > 6 ||
                gridIndex.Y < 0 || gridIndex.Y > 4) {
                return false;
            }

            if (Glob.GridStates[gridIndex.X, gridIndex.Y] != Glob.GridState.Free) {
                return false;
            }
        }

        return true;
    }

    private bool IsCenterInGridBounds() {
        return Glob.IsPointInGrid(GlobalPosition);
    }

    /// <summary>
    ///     将方块放置到指定网格坐标并占用对应格子。
    /// </summary>
    /// <param name="coords">网格坐标 (col, row)，范围 (0-6, 0-4)</param>
    public void PlaceAtGrid(Vector2I coords) {
        if (coords.X < 0 || coords.X >= 7 || coords.Y < 0 || coords.Y >= 5) {
            return;
        }

        var centerPos = Glob.GetGridPos(coords);
        GlobalPosition = centerPos;

        foreach (var part in _parts) {
            var gridPoint = Glob.FindNearestGridPoint(part.GlobalPosition);
            var gridIndex = Glob.GetGridCoords(gridPoint);
            if (gridIndex.X >= 0 && gridIndex.Y >= 0) {
                Glob.SetGridState(gridIndex.X, gridIndex.Y, Glob.GridState.Occupied);
            }
        }

        OriginalPos = GlobalPosition;
        IsPlaced = true;
        EmitSignalPlaced(this);
    }
}