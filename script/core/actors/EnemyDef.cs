using Godot;
using System;

[GlobalClass]
public partial class EnemyDef : Resource {
    // Enemy's name
    [Export] public String Name;

    // Enemy's turn description
    [Export] public EnemyTurnDef[] Turns;

    // Enemy's MaxHP
    [Export] public int MaxHP;
    [Export] public int StartingShield;

    // When will enemy's behaviors loop start
    [Export] public int LoopStartsAtTurn;
}
