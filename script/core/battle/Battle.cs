using Godot;
using System;
using System.Linq;
using System.Reflection;

public partial class Battle : Node2D {
    public override void _Ready() {
        Global.InitRng();
        Global.InitGrids();
        Global.GetBlock("ExampleBlock", new Vector2(100, 100), this);
        Global.GetBlock("ExampleMoveRight", new Vector2(200, 200), this);
    }

    private void AutoRegisterBlocks() {
        var types = Assembly.GetExecutingAssembly().GetTypes()
            .Where(t => t.GetCustomAttribute<BlockRegistererAttribute>() != null
                && typeof(AbstractBlockRegisterer).IsAssignableFrom(t));
        foreach (var type in types) {
            if (Activator.CreateInstance(type) is AbstractBlockRegisterer registerer) {
                registerer.Register();
            }
        }
    }
}
