#region

using System.Collections.Generic;
using System.Linq;
using Godot;

#endregion

// ReSharper disable CheckNamespace
public partial class Block : Node2D {
    [Signal]
    public delegate void PlacedEventHandler(Block block);

    public enum BlockFaction {
        Player,
        Enemy
    }

    public static bool InputLocked;

    private readonly List<BlockPart> _parts = [];
    [Export] public BlockDef Definition;
    public BlockFaction Faction = BlockFaction.Player;

    public bool IsPlaced;
    public bool IsPressed;
    public Vector2 OriginalPos;

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
            var part = new BlockPart {
                PartDefinition = def
            };
            _parts.Add(part);
            AddChild(part);
            if (!part.HasSignal("Pressed")) {
                continue;
            }

            part.Pressed += n => {
                if (!_parts.Contains(n) || InputLocked || Faction != BlockFaction.Player) {
                    return;
                }

                IsPressed = true;
                if (IsPlaced) {
                    LiftFromGrid();
                }
            };
            part.Released += n => {
                if (!_parts.Contains(n) || InputLocked || Faction != BlockFaction.Player) {
                    return;
                }

                IsPressed = false;
                if (CheckConditionP() && CheckConditionQ() && CheckConditionR()) {
                    GlobalPosition = Glob.FindNearestGridPoint(GlobalPosition);
                    foreach (var part in _parts) {
                        var gridPoint = Glob.FindNearestGridPoint(part.GlobalPosition);
                        var gridIndex = Glob.GetGridCoords(gridPoint);
                        if (gridIndex.X >= 0 && gridIndex.Y >= 0) {
                            Glob.SetGridState(gridIndex.X, gridIndex.Y,
                                Glob.GridState.Occupied);
                        }
                    }

                    OriginalPos = GlobalPosition;
                    IsPlaced = true;
                    EmitSignalPlaced(this);
                }
                else {
                    GlobalPosition = OriginalPos;
                }
            };
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

    private bool CheckConditionP() {
        return _parts.All(part => Glob.IsPointInGrid(part.GlobalPosition));
    }

    private bool CheckConditionQ() {
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

    private bool CheckConditionR() {
        return Glob.IsPointInGrid(GlobalPosition);
    }

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