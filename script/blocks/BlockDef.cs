#region

using Godot;

#endregion

[GlobalClass]
public partial class BlockDef : Resource {
    [Export] public string BlockName;
    [Export] public BlockPartDef[] PartDefinitions;
}