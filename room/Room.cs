#region

using Godot;

#endregion

public partial class Room : Node2D {
    protected Label _healthLabel;

    protected SaveLoad _saveLoad;
    protected Label _stageRoomLabel;
    [Export] public bool ShowStatusBar = true;

    public override void _Ready() {
        _saveLoad = GetTree().Root.GetNode<SaveLoad>("SaveLoad");
        _saveLoad.Load();

        if (ShowStatusBar) {
            // 场景中已预定义 StatusBar 节点，获取引用并显示
            GetNode<TextureRect>("TopBar").Visible = true;
            GetNode<TextureRect>("Heart").Visible = true;
            _healthLabel = GetNode<Label>("%HealthLabel");
            _healthLabel.Visible = true;
            _stageRoomLabel = GetNode<Label>("%StageRoomLabel");
            _stageRoomLabel.Visible = true;
            UpdateStageRoomLabel();
        }

        UpdateHealthFromSaveLoad();

        var player = GetTree().GetFirstNodeInGroup("Players") as Player;
        if (player != null) {
            var health = player.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
            if (health != null) {
                health.HealthChanged += OnHealthChanged;
                UpdateHealthDisplay(health.CurrentHealth, health.MaxHealth);
            }
        }

        // Player 已就绪后刷新状态栏（因为此时 player.RoomCount / StageCount 已由 SaveLoad 设好）
        UpdateStageRoomLabel();
    }

    public override void _ExitTree() {
        // 断开信号连接，防止 Room 被释放后 Player 还持有对该 Room 方法的引用
        if (IsInstanceValid(this)) {
            var player = GetTree().GetFirstNodeInGroup("Players") as Player;
            if (player != null) {
                var health = player.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
                if (health != null) {
                    health.HealthChanged -= OnHealthChanged;
                }
            }
        }

        _saveLoad?.Save();
    }

    protected void UpdateStageRoomLabel() {
        if (_stageRoomLabel == null) return;

        // 优先从 Player 节点读取（由 SaveLoad.SyncToGameState 设置），
        // 兜底从 DataResource 读取
        var player = GetTree().GetFirstNodeInGroup("Players") as Player;
        var rc = player?.RoomCount ?? _saveLoad?.Data?.RoomCount ?? 0;
        var sc = player?.StageCount ?? _saveLoad?.Data?.StageCount ?? 0;
        _stageRoomLabel.Text = $"Stage: {sc}    Room: {rc}";
    }

    protected void OnHealthChanged(int current, int max) {
        UpdateHealthDisplay(current, max);
    }

    private void UpdateHealthFromSaveLoad() {
        if (_healthLabel != null && _saveLoad?.Data != null) {
            _healthLabel.Text = $"{_saveLoad.Data.PlayerCurrentHealth}/{_saveLoad.Data.PlayerMaxHealth}";
        }
    }

    protected void UpdateHealthDisplay(int current, int max) {
        if (_healthLabel != null) {
            _healthLabel.Text = $"{current}/{max}";
        }
    }
}