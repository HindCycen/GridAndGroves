#region

using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

#endregion

public partial class PileComponent : Node2D {
    private readonly List<Block> _pile = [];

    public IReadOnlyList<Block> Pile => _pile.AsReadOnly();
    public int Count => _pile.Count;

    public void AddBlock(Block block) {
        ArgumentNullException.ThrowIfNull(block);

        _pile.Add(block);
    }

    public void AddBlocks(IEnumerable<Block> blocks) {
        ArgumentNullException.ThrowIfNull(blocks);

        foreach (var block in blocks) {
            AddBlock(block);
        }
    }

    public bool RemoveBlock(Block block) {
        return block != null && _pile.Remove(block);
    }

    public Block RemoveBlockAt(int index) {
        if (index < 0 || index >= _pile.Count) {
            throw new ArgumentOutOfRangeException(nameof(index));
        }

        var block = _pile[index];
        _pile.RemoveAt(index);
        return block;
    }

    public Block GetBlockReference(int index) {
        if (index < 0 || index >= _pile.Count) {
            throw new ArgumentOutOfRangeException(nameof(index));
        }

        return _pile[index];
    }

    public Block GetBlockReference(BlockDef definition) {
        var card = _pile.FirstOrDefault(b => b.Definition == definition);
        return card ??
               throw new InvalidOperationException($"No card with definition {definition.BlockName} found in pile");
    }

    public Block GetBlockCopy(int index) {
        if (index < 0 || index >= _pile.Count) {
            throw new ArgumentOutOfRangeException(nameof(index));
        }

        return CreateBlockCopy(_pile[index]);
    }

    public Block GetBlockCopy(BlockDef definition) {
        var card = _pile.FirstOrDefault(b => b.Definition == definition);
        return card == null
            ? throw new InvalidOperationException($"No card with definition {definition.BlockName} found in pile")
            : CreateBlockCopy(card);
    }

    public Block GetRandomBlockReference() {
        if (_pile.Count == 0) {
            throw new InvalidOperationException("Pile is empty");
        }

        var randomIndex = Glob.GetPileRand(_pile.Count);
        return _pile[randomIndex];
    }

    public Block GetRandomBlockCopy() {
        if (_pile.Count == 0) {
            throw new InvalidOperationException("Pile is empty");
        }

        var randomIndex = Glob.GetPileRand(_pile.Count);
        return CreateBlockCopy(_pile[randomIndex]);
    }

    private Block CreateBlockCopy(Block original) {
        return Glob.CreateBlock(original.Definition);
    }
}