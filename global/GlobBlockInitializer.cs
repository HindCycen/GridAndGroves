#region

using System.Collections.Generic;
using Godot;

#endregion

public partial class Glob {
    public static Dictionary<string, BlockDef> BlockDefs = [];

    public static bool SubscribeBlockDef(BlockDef blockDef) {
        if (blockDef == null) {
            GameLog.Err("ParseError: One blockdef is null");
            return false;
        }

        if (BlockDefs.ContainsKey(blockDef.BlockName)) {
            GameLog.Err($"ParseError: Blockdef with name {blockDef.BlockName} already exists");
            return false;
        }

        BlockDefs[blockDef.BlockName] = blockDef;
        return true;
    }


    public static Block GetBlock(string blockName, Vector2 globalPos, Node parent) {
        if (!BlockDefs.ContainsKey(blockName)) {
            GameLog.Err($"BlockFactory: No blockdef with name {blockName} found");
            return null;
        }

        var blockDef = BlockDefs[blockName];
        var block = CreateBlock(blockDef);
        block.GlobalPosition = globalPos;
        parent.AddChild(block);
        return block;
    }

    public static Block CreateBlock(BlockDef blockDef) {
        if (blockDef == null) {
            GameLog.Err("BlockFactory: BlockDef is null");
            return null;
        }

        var block = GD.Load<PackedScene>("res://blocks/Block.tscn").Instantiate<Block>();
        block.Definition = blockDef;
        return block;
    }

    public static Block CreateBlock(string blockName) {
        if (!BlockDefs.ContainsKey(blockName)) {
            GameLog.Err($"BlockFactory: No blockdef with name {blockName} found");
            return null;
        }

        return CreateBlock(BlockDefs[blockName]);
    }
}