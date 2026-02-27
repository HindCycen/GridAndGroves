using Godot;
using System;

[GlobalClass]
public partial class BlockDef : Resource {
    [Export] public string BlockName;
    [Export] public BlockPartDef[] PartDefinitions;
}
