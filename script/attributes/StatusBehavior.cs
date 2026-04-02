#region

using System;

#endregion

[AttributeUsage(AttributeTargets.Method)]
public class StatusBehaviorAttribute : Attribute {
    public Glob.StatExecuteAt Period;
}