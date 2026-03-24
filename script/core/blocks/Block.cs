#region

using System.Collections.Generic;
using System.Linq;
using Godot;

#endregion

// ReSharper disable CheckNamespace
public partial class Block : Node2D {
    private readonly List<BlockPart> _parts = [];
    private BattleContext _battleContext;
    private bool _wasPlaced;
    [Export] public BlockDef Definition;
    public bool IsPlaced;
    public bool IsPressed;
    public Vector2 OriginalPos;

    public override void _Ready() {
        var battleContexts = GetTree().GetNodesInGroup("BattleContext");
        if (battleContexts.Count > 0) {
            _battleContext = battleContexts[0] as BattleContext;
            SubscribeSignals(_battleContext);
        }
        else {
            GetTree().Root.Connect("BattleContextReady", new Callable(this, "OnBattleContextReady"));
        }

        OriginalPos = GlobalPosition;
        LoadParts();
    }

    private void SubscribeSignals(BattleContext battleContext) {
        battleContext.TurnStarted += () => {
            _wasPlaced = IsPlaced;
            IsPlaced = true;
        };
        battleContext.TurnEnded += () => {
            if (_wasPlaced) {
                QueueFree();
            }
            else {
                IsPlaced = _wasPlaced;
            }
        };
    }

    private void OnBattleContextReady() {
        var battleContext = GetTree().GetNodesInGroup("BattleContext")[0] as BattleContext;
        SubscribeSignals(battleContext);
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
            if (part.HasSignal("Pressed")) {
                part.Pressed += n => { IsPressed = _parts.Contains(n); };
                part.Released += n => {
                    if (_parts.Contains(n)) {
                        IsPressed = false;
                        if (CheckConditionP() && CheckConditionQ() && CheckConditionR()) {
                            GlobalPosition = Glob.FindNearestGridPoint(GlobalPosition);
                            foreach (var part in _parts) {
                                var nearestGridPoint = Glob.FindNearestGridPoint(part.GlobalPosition);
                                Glob.SetGridState((int) nearestGridPoint.X, (int) nearestGridPoint.Y,
                                    Glob.GridState.Occupied);
                            }
                    
                            IsPlaced = true;
                        }
                        else {
                            GlobalPosition = OriginalPos;
                        }
                    }
                };
            }
        }
    }


    private bool CheckConditionP() {
        if (IsPlaced) {
            return true;
        }

        foreach (var part in _parts) {
            if (!Glob.IsPointInGrid(part.GlobalPosition)) {
                return false;
            }
        }

        return true;
    }

    private bool CheckConditionQ() {
        if (IsPlaced) {
            return true;
        }

        foreach (var part in _parts) {
            var nearestGridPoint = Glob.FindNearestGridPoint(part.GlobalPosition);
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