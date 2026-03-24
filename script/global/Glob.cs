#region

using Godot;

#endregion

public partial class Glob : Node
{
    public override void _Ready()
    {
        // Autoload 初始化逻辑
        InitSeed(0);
        InitRng();
        InitGrids();
        AutoRegisterBlocks();
    }
}
