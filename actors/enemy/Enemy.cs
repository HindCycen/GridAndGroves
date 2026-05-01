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

        if (Definition != null) {
            var healthComponent = GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (healthComponent != null) {
                healthComponent.SetMaxHealth(Definition.MaxHealth);
            }

            if (Definition.Image != null) {
                var sprite = GetNode<AnimatedSprite2D>("ActorSprite");
                var frames = new SpriteFrames();
                frames.AddFrame("default", Definition.Image);
                sprite.SpriteFrames = frames;
                sprite.Play("default");
            }

            if (Definition.InitialStats != null) {
                var renderingComponent = GetNode<RenderingComponent>("RenderingComponent");
                var statsComponent = renderingComponent.StatsComponent;
                foreach (var statDef in Definition.InitialStats) {
                    if (statDef != null) {
                        var stat = new Stat { Definition = statDef };
                        statsComponent.AddStatus(stat);
                        stat.AddValue(statDef.MaxValue);
                    }
                }
            }
        }
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