using Godot;
using System;

public partial class BlockFactory : Node2D {
    [Export] private PackedScene _blockScene;

    public Block CreateBlock(BlockDef definition, Vector2 globalPosition, Node parent) {
        if (_blockScene == null) {
            GD.PushError("BlockFactory: _blockScene is null");
            return null;
        }
        if (definition == null) {
            GD.PushError("BlockFactory: definition is null"); 
            return null;
        }

        var block = _blockScene.Instantiate<Block>();
        block.Definition = definition;
        block.OriginalPos = globalPosition;
        block.GlobalPosition = globalPosition;
        parent.AddChild(block);
        return block;
    }
}
