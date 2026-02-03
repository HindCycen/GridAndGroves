using Godot;
using System;

[GlobalClass]
public partial class BlockDef : Resource {
    [Export] public BlockPartDef[] PartDefinitions;
}
