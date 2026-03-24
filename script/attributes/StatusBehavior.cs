using Godot;
using System;

[AttributeUsage(AttributeTargets.Method)]
public class StatusBehaviorAttribute : Attribute {
    public Global.StatExecuteAt Period;
}