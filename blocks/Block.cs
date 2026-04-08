#region

using System.Collections.Generic;
using System.Linq;
using Godot;

#endregion

// ReSharper disable CheckNamespace
public partial class Block : Node2D {
    private readonly List<BlockPart> _parts = [];
    private bool _wasPlaced;
    [Export] public BlockDef Definition;

    [Signal]
    public delegate void PlacedEventHandler(Block block);

    public bool IsPlaced;
    public bool IsPressed;
    public Vector2 OriginalPos;

    public override void _Ready() {
        var battleTime = GetTree().Root.GetNode<BattleTime>("BattleTime");
        SubscribeSignals(battleTime);

        OriginalPos = GlobalPosition;
        LoadParts();
    }

    private void SubscribeSignals(BattleTime battleTime) {
        battleTime.TurnStarted += () => {
            _wasPlaced = IsPlaced;
            IsPlaced = true;
        };
        battleTime.TurnEnded += () => {
            IsPlaced = false;
            _wasPlaced = false;
        };
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
                    foreach (var nearestGridPoint in _parts.Select(blockPart =>
                                 Glob.FindNearestGridPoint(blockPart.GlobalPosition))) {
                        Glob.SetGridState((int) nearestGridPoint.X, (int) nearestGridPoint.Y,
                            Glob.GridState.Occupied);
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
            if (gridIndex.X < 0 ||
                gridIndex.Y < 0 ||
                gridIndex.X >= Glob.GridSize ||
                gridIndex.Y >= Glob.GridSize) {
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