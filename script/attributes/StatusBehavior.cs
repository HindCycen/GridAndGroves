using Godot;
using System;

[AttributeUsage(AttributeTargets.Method)]
public class StatusBehaviorAttribute : Attribute {
    public Glob.StatExecuteAt Period;
}