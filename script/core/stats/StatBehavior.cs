using Godot;
using System;

[GlobalClass]
public partial class StatBehavior : Resource {
    private Stat _belongingStat;

    public void SetBelongingStat(Stat statName) {
        _belongingStat = statName;
    }
}