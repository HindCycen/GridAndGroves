#region

using Godot;

#endregion

public partial class Enemy : Node2D {
    private AIComponent _aiComponent;
    [Export] public int AttackDamage { get; set; } = 10;
    [Export] public EnemyDefinition Definition { get; set; }

    public override void _Ready() {
        AddToGroup("Enemies");
        _aiComponent = GetNodeOrNull<AIComponent>("AIComponent");
    }

    public void SetupAI(BlockPilesHere blockPilesHere) {
        if (_aiComponent == null) {
            _aiComponent = new AIComponent();
            AddChild(_aiComponent);
        }

        _aiComponent.Setup(blockPilesHere);
    }

    public void ExecuteTurn() {
        if (_aiComponent != null && Definition != null) {
            _aiComponent.ExecuteIntent(Definition);
        }
    }

    public void ClearBlocks() {
        _aiComponent?.ClearExistingBlocks();
    }
}