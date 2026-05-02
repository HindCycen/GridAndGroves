using Godot;

public partial class Room : Node2D {
    [Export] public bool ShowStatusBar = true;

    protected SaveLoad _saveLoad;
    protected Label _healthLabel;
    protected Label _stageRoomLabel;

    public override void _Ready() {
        _saveLoad = GetTree().Root.GetNode<SaveLoad>("SaveLoad");
        _saveLoad.Load();

        if (ShowStatusBar) {
            CreateStatusBar();
        }

        var player = GetTree().GetFirstNodeInGroup("Players") as Player;
        if (player != null) {
            var health = player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            if (health != null) {
                health.HealthChanged += OnHealthChanged;
                UpdateHealthDisplay(health.CurrentHealth, health.MaxHealth);
            }
        }
    }

    public override void _ExitTree() {
        _saveLoad?.Save();
    }

    private void CreateStatusBar() {
        var topBar = new TextureRect();
        topBar.Texture = GD.Load<Texture2D>("res://room/room_pictures/TopBar.png");
        topBar.SetSize(new Vector2(1920, 60));
        topBar.Position = new Vector2(0, 0);
        topBar.StretchMode = TextureRect.StretchModeEnum.Tile;
        AddChild(topBar);

        var heart = new TextureRect();
        heart.Texture = GD.Load<Texture2D>("res://room/room_pictures/Heart.png");
        heart.SetSize(new Vector2(32, 32));
        heart.Position = new Vector2(20, 14);
        heart.StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered;
        AddChild(heart);

        _healthLabel = new Label();
        _healthLabel.Position = new Vector2(100, 12);
        _healthLabel.SetSize(new Vector2(200, 36));
        _healthLabel.AddThemeFontSizeOverride("font_size", 28);
        AddChild(_healthLabel);

        _stageRoomLabel = new Label();
        _stageRoomLabel.Position = new Vector2(650, 12);
        _stageRoomLabel.SetSize(new Vector2(620, 36));
        _stageRoomLabel.AddThemeFontSizeOverride("font_size", 28);
        _stageRoomLabel.HorizontalAlignment = HorizontalAlignment.Center;
        AddChild(_stageRoomLabel);

        UpdateStageRoomLabel();
    }

    protected void UpdateStageRoomLabel() {
        if (_stageRoomLabel != null) {
            var rc = _saveLoad?.Data?.RoomCount ?? 0;
            var sc = _saveLoad?.Data?.StageCount ?? 0;
            _stageRoomLabel.Text = $"Stage: {sc}    Room: {rc}";
        }
    }

    protected void OnHealthChanged(int current, int max) {
        UpdateHealthDisplay(current, max);
    }

    protected void UpdateHealthDisplay(int current, int max) {
        if (_healthLabel != null) {
            _healthLabel.Text = $"{current}/{max}";
        }
    }
}
