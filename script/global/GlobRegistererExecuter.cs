#region

using System;
using System.Linq;
using System.Reflection;

#endregion

public partial class Glob {
    public static void AutoRegisterBlocks() {
        var types = Assembly.GetExecutingAssembly().GetTypes()
            .Where(t => t.GetCustomAttribute<BlockRegistererAttribute>() != null
                        && typeof(AbstractBlockRegisterer).IsAssignableFrom(t)
                        && !t.IsAbstract);
        foreach (var type in types) {
            if (Activator.CreateInstance(type) is AbstractBlockRegisterer registerer) {
                registerer.Register();
            }
        }
    }
}
