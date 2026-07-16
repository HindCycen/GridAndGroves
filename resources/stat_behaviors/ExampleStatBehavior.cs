#region

using Godot;

#endregion

public partial class ExampleStatBehavior : StatBehavior {
    [StatusBehavior(Period = Glob.StatExecuteAt.OnTurnEnded)]
    public void ExecuteStat() {
        GD.Print("Example Status Executed");
    }
}