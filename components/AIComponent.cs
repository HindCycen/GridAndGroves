#region

using System.Linq;
using Godot;

#endregion

[GlobalClass]
public partial class AIComponent : Node {
    private BlockPilesHere _blockPilesHere;
    private int _cycleIndex;
    private Node2D _owner;
    private int _repeatCount;

    public override void _Ready() {
        _owner = GetParent<Node2D>();
    }

    public void Setup(BlockPilesHere blockPilesHere) {
        _blockPilesHere = blockPilesHere;
    }

    public void Reset() {
        _cycleIndex = 0;
        _repeatCount = 0;
    }

    public IntentDefinition GetCurrentIntent(EnemyDefinition definition) {
        if (definition?.IntentCycle == null || definition.IntentCycle.Length == 0) {
            return null;
        }

        return definition.IntentCycle[_cycleIndex];
    }

    public void AdvanceTurn(EnemyDefinition definition) {
        if (definition?.IntentCycle == null || definition.IntentCycle.Length == 0) {
            return;
        }

        var intent = definition.IntentCycle[_cycleIndex];
        _repeatCount++;
        if (_repeatCount >= intent.RepeatCount) {
            _repeatCount = 0;
            _cycleIndex = (_cycleIndex + 1) % definition.IntentCycle.Length;
        }
    }

    public void ExecuteIntent(EnemyDefinition definition) {
        var intent = GetCurrentIntent(definition);
        if (intent?.BlockPlacements == null || _blockPilesHere == null) {
            return;
        }

        foreach (var placement in intent.BlockPlacements) {
            if (placement.Block == null) {
                continue;
            }

            var pos = placement.GridPosition;
            if (placement.RandomOffsetRange > 0) {
                var range = placement.RandomOffsetRange;
                pos.X += Glob.GetMiscRand(range * 2 + 1) - range;
                pos.Y += Glob.GetMiscRand(range * 2 + 1) - range;
                pos.X = Mathf.Clamp(pos.X, 0, 6);
                pos.Y = Mathf.Clamp(pos.Y, 0, 4);
            }

            pos = FindFreeCellNear(pos);
            if (pos.X < 0) continue;

            var block = Glob.CreateBlock(placement.Block);
            if (block == null) {
                continue;
            }

            block.Faction = Block.BlockFaction.Enemy;
            _blockPilesHere.AddChild(block);
            block.PlaceAtGrid(pos);
            _blockPilesHere.PlacedPile.AddBlock(block);
        }

        AdvanceTurn(definition);
    }

    public void ClearExistingBlocks() {
        if (_blockPilesHere == null) {
            return;
        }

        var oldBlocks = _blockPilesHere.PlacedPile.Pile
            .Where(b => b.Faction == Block.BlockFaction.Enemy).ToList();

        foreach (var block in oldBlocks) {
            _blockPilesHere.PlacedPile.RemoveBlock(block);
            foreach (var part in block.GetParts()) {
                var gridPoint = Glob.FindNearestGridPoint(part.GlobalPosition);
                var coords = Glob.GetGridCoords(gridPoint);
                if (coords.X >= 0 && coords.Y >= 0) {
                    Glob.SetGridState(coords.X, coords.Y, Glob.GridState.Free);
                }
            }

            if (block.GetParent() != null && IsInstanceValid(block.GetParent())) {
                block.GetParent().RemoveChild(block);
            }

            block.QueueFree();
        }
    }

    private static readonly Vector2I[] _searchOffsets = [
        Vector2I.Zero,
        new Vector2I(1, 0), new Vector2I(-1, 0), new Vector2I(0, 1), new Vector2I(0, -1),
        new Vector2I(1, 1), new Vector2I(-1, 1), new Vector2I(1, -1), new Vector2I(-1, -1),
        new Vector2I(2, 0), new Vector2I(-2, 0), new Vector2I(0, 2), new Vector2I(0, -2),
    ];

    private static Vector2I FindFreeCellNear(Vector2I center) {
        foreach (var offset in _searchOffsets) {
            var candidate = center + offset;
            if (candidate.X < 0 || candidate.X >= 7 || candidate.Y < 0 || candidate.Y >= 5)
                continue;
            if (Glob.GetGridState(candidate.X, candidate.Y) != Glob.GridState.Free)
                continue;
            return candidate;
        }
        return new Vector2I(-1, -1);
    }
}