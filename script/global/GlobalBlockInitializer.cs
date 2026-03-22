#region

using System.Collections.Generic;
using Godot;

#endregion

public abstract partial class Global {
    public static Dictionary<string, BlockDef> BlockDefs = [];

    public static bool SubscribeBlockDef(BlockDef blockDef) {
        if (blockDef == null) {
            GD.PrintErr("ParseError: One blockdef is null");
            return false;
        }

        if (BlockDefs.ContainsKey(blockDef.BlockName)) {
            GD.PrintErr($"ParseError: Blockdef with name {blockDef.BlockName} already exists");
            return false;
        }

        BlockDefs[blockDef.BlockName] = blockDef;
        return true;
    }


    public static Block GetBlock(string blockName, Vector2 globalPos, Node parent) {
        if (!BlockDefs.ContainsKey(blockName)) {
            GD.PushError($"BlockFactory: No blockdef with name {blockName} found");
            return null;
        }

        var blockDef = BlockDefs[blockName];
        var block = GD.Load<PackedScene>("res://scenes/blocks/Block.tscn").Instantiate<Block>();
        block.Definition = blockDef;
        block.GlobalPosition = globalPos;
        parent.AddChild(block);
        return block;
    }
}