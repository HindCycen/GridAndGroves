using Godot;
using System;

public partial class BattleController : Node {
    private int _currentTurn = 0;
    private Enemy _enemy;

    public override void _Ready() {
        _enemy = GetParent<Enemy>();
    }
}