#region

using System.Collections.Generic;
using System.Linq;
using Godot;

#endregion

// ReSharper disable CheckNamespace
public partial class Block : Node2D {
    private readonly List<BlockPart> _parts = [];
    [Export] public BlockDef Definition;

    [Signal]
    public delegate void PlacedEventHandler(Block block);

    public bool IsPlaced;
    public bool IsPressed;
    public Vector2 OriginalPos;

    public BlockPart[] GetParts() => _parts.ToArray();

    public override void _Ready() {
        OriginalPos = GlobalPosition;
        LoadParts();
    }


    public override void _Process(double delta) {
        if (IsPressed && !IsPlaced) {
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

            part.Pressed += n => { IsPressed = _parts.Contains(n); };
            part.Released += n => {
                if (!_parts.Contains(n)) {
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

                    IsPlaced = true;
                    EmitSignalPlaced(this);
                }
                else {
                    GlobalPosition = OriginalPos;
                }
            };
        }
    }


    private bool CheckConditionP() {
        if (IsPlaced) {
            return true;
        }

        return _parts.All(part => Glob.IsPointInGrid(part.GlobalPosition));
    }

    private bool CheckConditionQ() {
        if (IsPlaced) {
            return true;
        }

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
}