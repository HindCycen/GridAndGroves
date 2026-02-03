using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

// ReSharper disable CheckNamespace
public partial class Block : Node2D {
    [Export] public BlockDef Definition;
    private List<BlockPart> _parts = [];
    private BattleContext _battleContext;
    public Vector2 OriginalPos;
    public bool IsPressed = false;
    public bool IsPlaced = false;
    private bool _wasPlaced = false;

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
                            GlobalPosition = Global.FindNearestGridPoint(GlobalPosition);
                            foreach (var part in _parts) {
                                var nearestGridPoint = Global.FindNearestGridPoint(part.GlobalPosition);
                                Global.SetGridState((int) nearestGridPoint.X, (int) nearestGridPoint.Y, Global.GridState.Occupied);
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
            if (!Global.IsPointInGrid(part.GlobalPosition)) {
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
            var nearestGridPoint = Global.FindNearestGridPoint(part.GlobalPosition);
            if (!Global.IsPointInGrid(nearestGridPoint)) {
                return false;
            }
            var gridIndex = Global.GetGridCoords(nearestGridPoint);
            if (gridIndex.X < 0 ||
                gridIndex.Y < 0 ||
                gridIndex.X >= Global.GridSize ||
                gridIndex.Y >= Global.GridSize) {
                return false;
            }
            if (Global.GridStates[gridIndex.X, gridIndex.Y] != Global.GridState.Free) {
                return false;
            }
        }
        return true;
    }

    private bool CheckConditionR() {
        return Global.IsPointInGrid(GlobalPosition);
    }
}
