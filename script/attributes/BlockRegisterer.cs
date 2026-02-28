using System;

[AttributeUsage(AttributeTargets.Class, Inherited = true)]
public partial class BlockRegistererAttribute : Attribute {
    public BlockRegistererAttribute() {
    }
}